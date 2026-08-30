//
//  InPlaceRenderSnapshotTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation
import Testing

@testable import Easydict

// MARK: - InPlaceRenderSnapshotTests

/// Verifies that one render snapshot keeps its frame, positioned blocks, and
/// generation-scoped translation states together as an immutable UI value.
@Suite("In-place Render Snapshot", .tags(.inPlaceTranslation, .unit))
struct InPlaceRenderSnapshotTests {
    // MARK: Internal

    @Test("A new frame never carries a stale translation for a changed block")
    func keepsChangedBlockStateWithNewFrame() throws {
        let stableID = UUID()
        let previous = InPlaceRenderSnapshot(
            generation: 1,
            image: try #require(makeImage(width: 2, height: 2)),
            blocks: [
                translatedBlock(
                    id: stableID,
                    rect: CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.1),
                    sourceText: "before",
                    translatedText: "old translation",
                    status: .translated
                ),
            ],
            capturedAt: 1,
            detectedLanguage: .english
        )
        let current = InPlaceRenderSnapshot(
            generation: 2,
            image: try #require(makeImage(width: 3, height: 4)),
            blocks: [
                translatedBlock(
                    id: stableID,
                    rect: CGRect(x: 0.2, y: 0.2, width: 0.5, height: 0.1),
                    sourceText: "after",
                    translatedText: nil,
                    status: .pending
                ),
            ],
            capturedAt: 2,
            detectedLanguage: .english
        )

        #expect(previous.image.width == 2)
        #expect(previous.blocks.first?.translatedText == "old translation")
        #expect(current.generation == 2)
        #expect(current.image.width == 3)
        #expect(current.image.height == 4)
        #expect(current.blocks.first?.id == stableID)
        #expect(current.blocks.first?.block.sourceText == "after")
        #expect(current.blocks.first?.translatedText == nil)
        #expect(current.blocks.first?.status == .pending)
        #expect(!current.blocks.contains { $0.translatedText == "old translation" })
    }

    @Test("A cached translation uses the current block geometry")
    func reusesCachedTextWithCurrentGeometry() throws {
        let stableID = UUID()
        let previousRect = CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.1)
        let currentRect = CGRect(x: 0.55, y: 0.3, width: 0.35, height: 0.12)
        let reusedBlock = translatedBlock(
            id: stableID,
            rect: currentRect,
            sourceText: "unchanged source",
            translatedText: "cached translation",
            status: .translated,
            providerIdentifier: "provider-a"
        )
        let snapshot = InPlaceRenderSnapshot(
            generation: 7,
            image: try #require(makeImage()),
            blocks: [reusedBlock],
            capturedAt: 7,
            detectedLanguage: .english
        )

        #expect(snapshot.blocks.first?.id == stableID)
        #expect(snapshot.blocks.first?.block.normalizedRect == currentRect)
        #expect(snapshot.blocks.first?.block.normalizedRect != previousRect)
        #expect(snapshot.blocks.first?.translatedText == "cached translation")
        #expect(snapshot.blocks.first?.providerIdentifier == "provider-a")
        #expect(snapshot.translatedBlockCount == 1)
    }

    @Test("Partial failure preserves every block status and counts only successes")
    func representsPartialFailure() throws {
        let blocks = [
            translatedBlock(
                sourceText: "translated",
                translatedText: "success",
                status: .translated,
                readingOrder: 0
            ),
            translatedBlock(
                sourceText: "pending",
                translatedText: nil,
                status: .pending,
                readingOrder: 1
            ),
            translatedBlock(
                sourceText: "offline",
                translatedText: nil,
                status: .failed(.network),
                readingOrder: 2
            ),
            translatedBlock(
                sourceText: "unauthorized",
                translatedText: nil,
                status: .failed(.authentication),
                readingOrder: 3
            ),
        ]
        let snapshot = InPlaceRenderSnapshot(
            generation: 9,
            image: try #require(makeImage()),
            blocks: blocks,
            capturedAt: 9,
            detectedLanguage: .english
        )

        #expect(snapshot.blocks.map(\.status) == [
            .translated,
            .pending,
            .failed(.network),
            .failed(.authentication),
        ])
        #expect(snapshot.blocks.map(\.block.readingOrder) == [0, 1, 2, 3])
        #expect(snapshot.translatedBlockCount == 1)
        #expect(snapshot.blocks.filter { block in
            if case .failed = block.status {
                return true
            }
            return false
        }.count == 2)
    }

    @Test("Original and translated display modes reuse the same render snapshot")
    func keepsDisplayModeOutsideSnapshot() throws {
        let snapshot = InPlaceRenderSnapshot(
            generation: 11,
            image: try #require(makeImage(width: 4, height: 3)),
            blocks: [
                translatedBlock(
                    sourceText: "source",
                    translatedText: "translation",
                    status: .translated
                ),
            ],
            capturedAt: 42,
            detectedLanguage: .english
        )
        let originalBlocks = snapshot.blocks
        var renderMode = InPlaceTranslationRenderMode.translated

        renderMode = .original

        #expect(renderMode == .original)
        #expect(snapshot.generation == 11)
        #expect(snapshot.image.width == 4)
        #expect(snapshot.image.height == 3)
        #expect(snapshot.blocks == originalBlocks)

        renderMode = .translated

        #expect(renderMode == .translated)
        #expect(snapshot.generation == 11)
        #expect(snapshot.blocks == originalBlocks)
        #expect(snapshot.blocks.first?.translatedText == "translation")
    }

    // MARK: Private

    private func translatedBlock(
        id: UUID = UUID(),
        rect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.1),
        sourceText: String,
        translatedText: String?,
        status: InPlaceBlockTranslationStatus,
        readingOrder: Int = 0,
        providerIdentifier: String = "provider"
    )
        -> InPlaceTranslatedBlock {
        InPlaceTranslatedBlock(
            block: InPlaceOCRBlock(
                id: id,
                normalizedRect: rect,
                sourceText: sourceText,
                detectedLanguage: .english,
                confidence: 0.98,
                readingOrder: readingOrder
            ),
            translatedText: translatedText,
            status: status,
            providerIdentifier: providerIdentifier
        )
    }

    private func makeImage(width: Int = 2, height: Int = 2) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
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
