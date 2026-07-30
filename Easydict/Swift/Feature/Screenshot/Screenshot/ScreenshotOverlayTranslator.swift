//
//  ScreenshotOverlayTranslator.swift
//  Easydict
//
//  Created by bsythegreat on 2026/7/29.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

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
        let sessionID = ScreenshotTranslationOverlay.shared.begin(screen: screen, rect: rect)

        Task {
            do {
                let result = try await AppleOCREngine().recognizeText(image: image)
                guard let observations = result.raw as? [EZRecognizedTextObservation],
                      !observations.isEmpty else {
                    throw QueryError.error(type: .noResult)
                }

                let source = result.from
                let target = EZLanguageManager.shared().userTargetLanguage(
                    withSourceLanguage: source
                )
                let serviceID = try translationServiceID(from: source, to: target)
                let items = try await translate(
                    observations,
                    with: serviceID,
                    from: source,
                    to: target
                )
                guard !items.isEmpty else {
                    throw QueryError.error(type: .noResult)
                }

                ScreenshotTranslationOverlay.shared.show(
                    image: image,
                    items: items,
                    screen: screen,
                    rect: rect,
                    mode: mode,
                    sessionID: sessionID
                )
            } catch {
                logError("Screenshot overlay translation failed: \(error)")
                guard ScreenshotTranslationOverlay.shared.isActive(sessionID) else { return }
                ScreenshotTranslationOverlay.shared.close()
                showError("screenshot.overlay.error.translation_failed")
            }
        }
    }

    // MARK: Private

    private func translationServiceID(from: Language, to: Language) throws -> String {
        let services = LocalStorage.shared().allServices(.main)
        guard let service = services.first(where: {
            $0.enabled
                && $0.enabledQuery
                && $0.languageCode(forLanguage: from) != nil
                && $0.languageCode(forLanguage: to) != nil
        }) else {
            throw QueryError.error(type: .unsupportedLanguage)
        }
        return service.serviceTypeWithUniqueIdentifier()
    }

    private func translate(
        _ observations: [EZRecognizedTextObservation],
        with serviceID: String,
        from: Language,
        to: Language
    ) async throws
        -> [ScreenshotTranslationItem] {
        var items: [ScreenshotTranslationItem] = []
        for observation in observations where !observation.firstText.trim().isEmpty {
            guard let service = QueryServiceFactory.shared.service(withTypeId: serviceID) else {
                throw QueryError.error(type: .api)
            }
            let model = QueryModel()
            model.inputText = observation.firstText
            model.userSourceLanguage = from
            model.userTargetLanguage = to
            model.detectedLanguage = from
            model.needDetectLanguage = false
            let result = try await service.startQuery(model)
            guard let text = result.translatedText?.trim(), !text.isEmpty else { continue }
            items.append(
                ScreenshotTranslationItem(text: text, boundingBox: observation.boundingBox)
            )
        }
        return items
    }

    private func showError(_ key: String) {
        EZToast.showText(NSLocalizedString(key, comment: ""))
    }
}
