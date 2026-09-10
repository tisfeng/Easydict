//
//  ScreenshotOverlayTranslator.swift
//  Easydict
//
//  Created by bsythegreat on 2026/7/29.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

// MARK: - ScreenshotOverlayTranslator

/// Coordinates Apple OCR, the selected translation service, and spatial overlay presentation.
@MainActor
@objcMembers
final class ScreenshotOverlayTranslator: NSObject {
    // MARK: Internal

    static let shared = ScreenshotOverlayTranslator()

    @objc(translateImage:)
    func translate(image: NSImage) {
        guard let screen = Screenshot.shared.lastScreen else {
            showError("screenshot.overlay.error.capture_location")
            return
        }
        let rect = Screenshot.shared.lastScreenshotRect
        let mode = MyConfiguration.shared.screenshotTranslateDisplayMode
        let sourceLanguage = MyConfiguration.shared.fromLanguage
        let sessionID = ScreenshotTranslationOverlay.shared.begin(screen: screen, rect: rect)

        let task = Task {
            defer {
                ScreenshotTranslationOverlay.shared.finishTask(sessionID)
            }
            do {
                let excludedRegions = ScreenshotTranslationOverlay.shared.excludedRegions(for: sessionID)
                let visibleImage = image.masking(excludedRegions)
                let result = try await AppleOCREngine().recognizeText(
                    image: visibleImage,
                    language: sourceLanguage
                )
                try Task.checkCancellation()
                guard let observations = result.raw as? [EZRecognizedTextObservation],
                      !observations.isEmpty else {
                    throw QueryError.error(type: .noResult)
                }

                let visibleObservations = observations.filter { observation in
                    !excludedRegions.contains { region in
                        region.intersects(observation.boundingBox)
                    }
                }
                guard !visibleObservations.isEmpty else {
                    ScreenshotTranslationOverlay.shared.close(sessionID)
                    return
                }

                let source = result.from
                let target = overlayTargetLanguage(for: source)
                let translation = try await translate(
                    visibleObservations,
                    from: source,
                    to: target
                ) { service in
                    ScreenshotTranslationOverlay.shared.showTranslationProgress(
                        service: service,
                        screen: screen,
                        rect: rect,
                        sessionID: sessionID
                    )
                }

                ScreenshotTranslationOverlay.shared.show(
                    content: ScreenshotTranslationContent(
                        image: visibleImage,
                        items: translation.items,
                        serviceName: translation.serviceName,
                        serviceIconName: translation.serviceIconName
                    ),
                    screen: screen,
                    rect: rect,
                    mode: mode,
                    sessionID: sessionID
                )
            } catch {
                logError("Screenshot overlay translation failed: \(error)")
                guard ScreenshotTranslationOverlay.shared.isActive(sessionID) else { return }
                ScreenshotTranslationOverlay.shared.close(sessionID)
                showError("screenshot.overlay.error.translation_failed")
            }
        }
        ScreenshotTranslationOverlay.shared.setTask(task, for: sessionID)
    }

    // MARK: Private

    /// Uses the configured target language unless the user selected automatic translation.
    private func overlayTargetLanguage(for source: Language) -> Language {
        let configuredTarget = MyConfiguration.shared.toLanguage
        guard configuredTarget == .auto else { return configuredTarget }
        return EZLanguageManager.shared().userTargetLanguage(withSourceLanguage: source)
    }

    private func translationServices(from: Language, to: Language) throws
        -> [QueryService] {
        let services = LocalStorage.shared().allServices(.screenshotOverlay).filter {
            $0.enabled
                && $0.supportsOverlayTranslation
                && $0.languageCode(forLanguage: from) != nil
                && $0.languageCode(forLanguage: to) != nil
        }
        guard !services.isEmpty else {
            throw QueryError.error(type: .unsupportedLanguage)
        }
        return services
    }

    private func translate(
        _ observations: [EZRecognizedTextObservation],
        from: Language,
        to: Language,
        onServiceStart: (QueryService) -> ()
    ) async throws
        -> ScreenshotOverlayResult {
        let services = try translationServices(from: from, to: to)
        var latestError: (any Error)?

        for service in services {
            try Task.checkCancellation()
            onServiceStart(service)
            do {
                guard let result = try await translate(
                    observations,
                    with: service,
                    from: from,
                    to: to
                ) else {
                    continue
                }
                return result
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                latestError = error
                logError(
                    "Screenshot overlay service failed: "
                        + "\(service.serviceTypeWithUniqueIdentifier()), \(error)"
                )
            }
        }

        throw latestError ?? QueryError.error(type: .noResult)
    }

    private func translate(
        _ observations: [EZRecognizedTextObservation],
        with service: QueryService,
        from: Language,
        to: Language
    ) async throws
        -> ScreenshotOverlayResult? {
        var items: [ScreenshotTranslationItem] = []
        var usedServiceID: String?
        for observation in observations where !observation.firstText.trim().isEmpty {
            try Task.checkCancellation()
            let model = QueryModel()
            model.inputText = observation.firstText
            model.userSourceLanguage = from
            model.userTargetLanguage = to
            model.detectedLanguage = from
            model.needDetectLanguage = false
            let result = try await startQuery(model, with: service)
            if let error = result.error {
                throw error
            }
            guard let text = result.translatedText?.trim(), !text.isEmpty else { continue }
            usedServiceID = result.serviceTypeWithUniqueIdentifier
            items.append(
                ScreenshotTranslationItem(text: text, boundingBox: observation.boundingBox)
            )
        }
        guard !items.isEmpty,
              let usedServiceID,
              let usedService = QueryServiceFactory.shared.service(withTypeId: usedServiceID) else {
            return nil
        }
        return ScreenshotOverlayResult(
            items: items,
            serviceName: usedService.name(),
            serviceIconName: usedService.serviceType().rawValue
        )
    }

    /// Resets reused service state and records every attempted overlay request.
    private func startQuery(
        _ model: QueryModel,
        with service: QueryService
    ) async throws
        -> QueryResult {
        service.resetServiceResult()
        defer {
            LocalStorage.shared().increaseQueryService(service)
        }
        return try await service.startQuery(model)
    }

    private func showError(_ key: String) {
        EZToast.showText(NSLocalizedString(key, comment: ""))
    }
}

// MARK: - ScreenshotOverlayResult

/// Couples translated items with the service that actually produced them.
private struct ScreenshotOverlayResult {
    let items: [ScreenshotTranslationItem]
    let serviceName: String
    let serviceIconName: String
}

extension QueryService {
    /// Whether this service can provide translated text for screenshot overlays.
    var supportsOverlayTranslation: Bool {
        let unsupportedTypes: [ServiceType] = [
            .appleDictionary,
            .mDict,
            .polishing,
            .summary,
        ]
        return !unsupportedTypes.contains(serviceType())
            && supportedQueryType().contains(.translation)
    }
}

extension NSImage {
    /// Covers normalized regions that belong to earlier OCR result windows.
    fileprivate func masking(_ regions: [CGRect]) -> NSImage {
        guard !regions.isEmpty else { return self }

        return NSImage(size: size, flipped: false) { bounds in
            self.draw(in: bounds)
            guard let context = NSGraphicsContext.current else { return true }
            context.saveGraphicsState()
            context.compositingOperation = .copy
            NSColor.windowBackgroundColor.setFill()
            for region in regions {
                NSBezierPath(
                    rect: CGRect(
                        x: region.minX * bounds.width,
                        y: region.minY * bounds.height,
                        width: region.width * bounds.width,
                        height: region.height * bounds.height
                    )
                ).fill()
            }
            context.restoreGraphicsState()
            return true
        }
    }
}
