//
//  InPlaceOCRBlockMatcherTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Verifies stable block identity and semantic change classification across OCR generations.
@Suite("In-place OCR Block Matcher", .tags(.inPlaceTranslation, .ocr, .unit))
struct InPlaceOCRBlockMatcherTests {
    // MARK: Internal

    @Test("Same text and geometry keep the previous identity as unchanged")
    func preservesUnchangedBlockIdentity() throws {
        let stableID = UUID()
        let previous = block(id: stableID, text: "Hello", rect: rect(0.1, 0.1))
        let current = block(text: "  Hello\n", rect: rect(0.101, 0.099))

        let result = InPlaceOCRBlockMatcher().match(previous: [previous], current: [current])

        #expect(try #require(result.blocks.first).id == stableID)
        #expect(result.unchangedBlockIDs == [stableID])
        #expect(result.geometryOnlyBlockIDs.isEmpty)
        #expect(result.changedBlockIDs.isEmpty)
        #expect(result.removedBlockIDs.isEmpty)
    }

    @Test("Same text in a moved region reuses translation but reports geometry-only change")
    func classifiesGeometryOnlyMovement() throws {
        let stableID = UUID()
        let previous = block(id: stableID, text: "Hello", rect: rect(0.1, 0.1))
        let current = block(text: "Hello", rect: rect(0.5, 0.5))

        let result = InPlaceOCRBlockMatcher().match(previous: [previous], current: [current])

        #expect(try #require(result.blocks.first).id == stableID)
        #expect(result.geometryOnlyBlockIDs == [stableID])
        #expect(result.changedBlockIDs.isEmpty)
        #expect(result.removedBlockIDs.isEmpty)
    }

    @Test("Changed text in an overlapping region keeps identity and requires translation")
    func classifiesChangedTextAtSamePosition() throws {
        let stableID = UUID()
        let previous = block(id: stableID, text: "Before", rect: rect(0.1, 0.1))
        let current = block(text: "After", rect: rect(0.11, 0.1))

        let result = InPlaceOCRBlockMatcher().match(previous: [previous], current: [current])

        #expect(try #require(result.blocks.first).id == stableID)
        #expect(result.changedBlockIDs == [stableID])
        #expect(result.removedBlockIDs.isEmpty)
    }

    @Test("Unrelated content is added while the unmatched prior block is removed")
    func classifiesAdditionAndRemoval() throws {
        let removedID = UUID()
        let newID = UUID()
        let previous = block(id: removedID, text: "Old", rect: rect(0.05, 0.05))
        let current = block(id: newID, text: "New", rect: rect(0.75, 0.75))

        let result = InPlaceOCRBlockMatcher().match(previous: [previous], current: [current])

        #expect(try #require(result.blocks.first).id == newID)
        #expect(result.changedBlockIDs == [newID])
        #expect(result.removedBlockIDs == [removedID])
    }

    @Test("Duplicate text uses nearest geometry instead of array position")
    func disambiguatesDuplicateTextByGeometry() {
        let leftID = UUID()
        let rightID = UUID()
        let previous = [
            block(id: leftID, text: "Repeat", rect: rect(0.1, 0.2), order: 0),
            block(id: rightID, text: "Repeat", rect: rect(0.7, 0.2), order: 1),
        ]
        let current = [
            block(text: "Repeat", rect: rect(0.69, 0.2), order: 0),
            block(text: "Repeat", rect: rect(0.11, 0.2), order: 1),
        ]

        let result = InPlaceOCRBlockMatcher().match(previous: previous, current: current)

        #expect(result.blocks.map(\.id) == [rightID, leftID])
        #expect(result.geometryOnlyBlockIDs == [leftID, rightID])
        #expect(result.changedBlockIDs.isEmpty)
        #expect(result.removedBlockIDs.isEmpty)
    }

    // MARK: Private

    private func block(
        id: UUID = UUID(),
        text: String,
        rect: CGRect,
        order: Int = 0
    )
        -> InPlaceOCRBlock {
        InPlaceOCRBlock(
            id: id,
            normalizedRect: rect,
            sourceText: text,
            detectedLanguage: .english,
            confidence: 1,
            readingOrder: order
        )
    }

    private func rect(_ x: CGFloat, _ y: CGFloat) -> CGRect {
        CGRect(x: x, y: y, width: 0.2, height: 0.1)
    }
}
