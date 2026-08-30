//
//  InPlaceTranslationViewModelTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults
import Testing

@testable import Easydict

// MARK: - InPlaceTranslationViewModelTests

/// Verifies main-actor generation publication and request-free display-mode behavior.
@MainActor
@Suite("In-place Translation View Model", .serialized, .tags(.inPlaceTranslation, .unit))
struct InPlaceTranslationViewModelTests {
    // MARK: Internal

    @Test("A stale generation cannot replace the latest render snapshot")
    func rejectsStaleSnapshotPublication() throws {
        let viewModel = makeViewModel()
        let newest = try snapshot(generation: 2, text: "newest")
        let stale = try snapshot(generation: 1, text: "stale")

        viewModel.publish(snapshot: newest)
        viewModel.publish(snapshot: stale)

        #expect(viewModel.snapshot?.generation == 2)
        #expect(viewModel.snapshot?.blocks.first?.translatedText == "newest")
    }

    @Test("Publishing a replacement snapshot clears only a missing selected block")
    func maintainsValidBlockSelection() throws {
        let viewModel = makeViewModel()
        let selectedID = UUID()
        let selected = try snapshot(generation: 1, text: "first", blockID: selectedID)
        viewModel.publish(snapshot: selected)
        viewModel.selectedBlockID = selectedID

        viewModel.publish(snapshot: try snapshot(generation: 2, text: "same", blockID: selectedID))
        #expect(viewModel.selectedBlockID == selectedID)

        viewModel.publish(snapshot: try snapshot(generation: 3, text: "replacement"))
        #expect(viewModel.selectedBlockID == nil)
    }

    @Test("Temporarily showing source pixels never mutates the chosen display mode")
    func temporarilyShowsOriginalWithoutChangingPreference() {
        let viewModel = makeViewModel(renderMode: .translated)

        viewModel.showOriginalTemporarily(true)
        #expect(viewModel.effectiveRenderMode == .original)
        #expect(viewModel.configuration.renderMode == .translated)

        viewModel.showOriginalTemporarily(false)
        #expect(viewModel.effectiveRenderMode == .translated)
    }

    @Test("Swapping from Auto uses the detected language as the new target")
    func swapsAutomaticSourceUsingDetectedLanguage() throws {
        let viewModel = makeViewModel(source: .auto, target: .english)
        viewModel.publish(
            snapshot: try snapshot(
                generation: 1,
                text: "translation",
                detectedLanguage: .japanese
            )
        )

        viewModel.swapLanguages()

        #expect(viewModel.configuration.sourceLanguage == .english)
        #expect(viewModel.configuration.targetLanguage == .japanese)
    }

    @Test("Swapping clamps an unsupported old source to a provider target")
    func clampsSwappedTargetToProviderSupport() {
        let resolver = ViewModelServiceResolver(
            supportedLanguages: ["provider": [.english, .simplifiedChinese]]
        )
        let viewModel = makeViewModel(
            source: .japanese,
            target: .english,
            serviceResolver: resolver
        )

        viewModel.swapLanguages()

        #expect(viewModel.configuration.sourceLanguage == .english)
        #expect(viewModel.configuration.targetLanguage == .simplifiedChinese)
    }

    @Test("No eligible service clears the active selection and language choices")
    func clearsSelectionWhenNoServiceIsAvailable() {
        let previousIdentifier = Defaults[.inPlaceTranslationServiceIdentifier]
        defer { Defaults[.inPlaceTranslationServiceIdentifier] = previousIdentifier }
        let resolver = ViewModelServiceResolver(options: [], supportedLanguages: [:])

        let viewModel = makeViewModel(serviceResolver: resolver)

        #expect(viewModel.serviceOptions.isEmpty)
        #expect(viewModel.availableTargetLanguages.isEmpty)
        #expect(viewModel.configuration.serviceIdentifier.isEmpty)
    }

    @Test("Copying a selected pending block never falls back to other translations")
    func doesNotCopyOtherBlocksForPendingSelection() throws {
        let pasteboard = NSPasteboard(
            name: .init("com.easydict.tests.in-place-copy.\(UUID().uuidString)")
        )
        pasteboard.clearContents()
        defer { pasteboard.clearContents() }
        let viewModel = makeViewModel(pasteboard: pasteboard)
        let pendingID = UUID()
        let snapshot = InPlaceRenderSnapshot(
            generation: 1,
            image: try #require(makeImage()),
            blocks: [
                translatedBlock(id: pendingID, text: nil, status: .pending, order: 0),
                translatedBlock(text: "other translation", status: .translated, order: 1),
            ],
            capturedAt: 1,
            detectedLanguage: .english
        )
        viewModel.publish(snapshot: snapshot)
        viewModel.selectedBlockID = pendingID
        pasteboard.setString("pending-copy-sentinel", forType: .string)

        viewModel.copyTranslation()

        #expect(pasteboard.string(forType: .string) == "pending-copy-sentinel")
    }

    // MARK: Private

    private func makeViewModel(
        source: Language = .english,
        target: Language = .simplifiedChinese,
        renderMode: InPlaceTranslationRenderMode = .translated,
        serviceResolver: any InPlaceTranslationServiceResolving = ViewModelServiceResolver(),
        pasteboard: NSPasteboard? = nil
    )
        -> InPlaceTranslationViewModel {
        let configuration = InPlaceTranslationConfiguration(
            sourceLanguage: source,
            targetLanguage: target,
            serviceIdentifier: "provider",
            liveUpdatesEnabled: true,
            isPinned: true,
            renderMode: renderMode
        )
        if let pasteboard {
            return InPlaceTranslationViewModel(
                configuration: configuration,
                serviceResolver: serviceResolver,
                pasteboard: pasteboard
            )
        }
        return InPlaceTranslationViewModel(
            configuration: configuration,
            serviceResolver: serviceResolver
        )
    }

    private func snapshot(
        generation: UInt64,
        text: String,
        blockID: UUID = UUID(),
        detectedLanguage: Language = .english
    ) throws
        -> InPlaceRenderSnapshot {
        let block = InPlaceOCRBlock(
            id: blockID,
            normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.1),
            sourceText: "source",
            detectedLanguage: detectedLanguage,
            confidence: 1,
            readingOrder: 0
        )
        return InPlaceRenderSnapshot(
            generation: generation,
            image: try #require(makeImage()),
            blocks: [
                InPlaceTranslatedBlock(
                    block: block,
                    translatedText: text,
                    status: .translated,
                    providerIdentifier: "provider"
                ),
            ],
            capturedAt: TimeInterval(generation),
            detectedLanguage: detectedLanguage
        )
    }

    private func translatedBlock(
        id: UUID = UUID(),
        text: String?,
        status: InPlaceBlockTranslationStatus,
        order: Int
    )
        -> InPlaceTranslatedBlock {
        InPlaceTranslatedBlock(
            block: InPlaceOCRBlock(
                id: id,
                normalizedRect: CGRect(
                    x: 0.1,
                    y: 0.1 + CGFloat(order) * 0.2,
                    width: 0.5,
                    height: 0.1
                ),
                sourceText: "source-\(order)",
                detectedLanguage: .english,
                confidence: 1,
                readingOrder: order
            ),
            translatedText: text,
            status: status,
            providerIdentifier: "provider"
        )
    }

    private func makeImage() -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: 2,
            height: 2,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        return context.makeImage()
    }
}

// MARK: - ViewModelServiceResolver

/// Supplies stable provider metadata without reading the user's service configuration.
private final class ViewModelServiceResolver: InPlaceTranslationServiceResolving {
    // MARK: Lifecycle

    init(
        options: [InPlaceTranslationServiceOption] = [
            InPlaceTranslationServiceOption(identifier: "provider", displayName: "Provider"),
        ],
        supportedLanguages: [String: [Language]] = [
            "provider": [.english, .simplifiedChinese, .japanese],
        ]
    ) {
        self.availableOptions = options
        self.languagesByIdentifier = supportedLanguages
    }

    // MARK: Internal

    func options() -> [InPlaceTranslationServiceOption] {
        availableOptions
    }

    func resolveSelection(
        _ storedIdentifier: String,
        availableOptions: [InPlaceTranslationServiceOption]
    )
        -> InPlaceTranslationServiceResolution {
        if availableOptions.contains(where: { $0.identifier == storedIdentifier }) {
            return InPlaceTranslationServiceResolution(
                identifier: storedIdentifier,
                shouldResetStoredSelection: false
            )
        }
        return InPlaceTranslationServiceResolution(
            identifier: availableOptions.first?.identifier,
            shouldResetStoredSelection: true
        )
    }

    func supportedLanguages(identifier: String) -> [Language] {
        languagesByIdentifier[identifier] ?? []
    }

    // MARK: Private

    private let availableOptions: [InPlaceTranslationServiceOption]
    private let languagesByIdentifier: [String: [Language]]
}
