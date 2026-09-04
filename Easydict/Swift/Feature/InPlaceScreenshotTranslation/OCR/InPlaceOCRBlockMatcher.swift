//
//  InPlaceOCRBlockMatcher.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation

// MARK: - InPlaceOCRBlockMatchResult

/// Carries stable block identities and the exact semantic change classification.
struct InPlaceOCRBlockMatchResult: Equatable, Sendable {
    let blocks: [InPlaceOCRBlock]
    let unchangedBlockIDs: Set<UUID>
    let geometryOnlyBlockIDs: Set<UUID>
    let changedBlockIDs: Set<UUID>
    let removedBlockIDs: Set<UUID>
}

// MARK: - InPlaceOCRBlockMatcher

/// Matches successive OCR blocks by normalized text and geometry so unchanged
/// translations can be reused without confusing duplicate text regions.
struct InPlaceOCRBlockMatcher: Sendable {
    // MARK: Lifecycle

    init(minimumIntersectionOverUnion: CGFloat = 0.45) {
        self.minimumIntersectionOverUnion = minimumIntersectionOverUnion
    }

    // MARK: Internal

    let minimumIntersectionOverUnion: CGFloat

    func match(
        previous: [InPlaceOCRBlock],
        current: [InPlaceOCRBlock]
    )
        -> InPlaceOCRBlockMatchResult {
        var unmatchedPrevious = Set(previous.indices)
        var matchedBlocks: [InPlaceOCRBlock] = []
        var unchanged = Set<UUID>()
        var geometryOnly = Set<UUID>()
        var changed = Set<UUID>()

        for currentBlock in current {
            let currentText = currentBlock.sourceFingerprint
            let exactCandidates = unmatchedPrevious.filter {
                previous[$0].sourceFingerprint == currentText
            }
            let exactIndex = bestCandidate(
                for: currentBlock,
                candidates: exactCandidates,
                previous: previous,
                requiresOverlap: false
            )

            if let exactIndex {
                let previousBlock = previous[exactIndex]
                unmatchedPrevious.remove(exactIndex)
                let stableBlock = currentBlock.replacingID(previousBlock.id)
                matchedBlocks.append(stableBlock)
                if approximatelyEqual(previousBlock.normalizedRect, stableBlock.normalizedRect) {
                    unchanged.insert(stableBlock.id)
                } else {
                    geometryOnly.insert(stableBlock.id)
                }
                continue
            }

            let changedIndex = bestCandidate(
                for: currentBlock,
                candidates: unmatchedPrevious,
                previous: previous,
                requiresOverlap: true
            )
            if let changedIndex {
                let stableBlock = currentBlock.replacingID(previous[changedIndex].id)
                unmatchedPrevious.remove(changedIndex)
                matchedBlocks.append(stableBlock)
                changed.insert(stableBlock.id)
            } else {
                matchedBlocks.append(currentBlock)
                changed.insert(currentBlock.id)
            }
        }

        return InPlaceOCRBlockMatchResult(
            blocks: matchedBlocks,
            unchangedBlockIDs: unchanged,
            geometryOnlyBlockIDs: geometryOnly,
            changedBlockIDs: changed,
            removedBlockIDs: Set(unmatchedPrevious.map { previous[$0].id })
        )
    }

    // MARK: Private

    private func bestCandidate(
        for block: InPlaceOCRBlock,
        candidates: Set<Int>,
        previous: [InPlaceOCRBlock],
        requiresOverlap: Bool
    )
        -> Int? {
        candidates
            .compactMap { index -> (index: Int, score: CGFloat)? in
                let previousBlock = previous[index]
                let overlap = intersectionOverUnion(
                    block.normalizedRect,
                    previousBlock.normalizedRect
                )
                if requiresOverlap, overlap < minimumIntersectionOverUnion {
                    return nil
                }
                let distance = hypot(
                    block.normalizedRect.midX - previousBlock.normalizedRect.midX,
                    block.normalizedRect.midY - previousBlock.normalizedRect.midY
                )
                let orderPenalty = CGFloat(abs(block.readingOrder - previousBlock.readingOrder)) * 0.01
                return (index, overlap * 2 - distance - orderPenalty)
            }
            .max { $0.score < $1.score }?
            .index
    }

    private func intersectionOverUnion(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        let unionArea = lhs.width * lhs.height + rhs.width * rhs.height
            - intersection.width * intersection.height
        guard unionArea > 0 else { return 0 }
        return intersection.width * intersection.height / unionArea
    }

    private func approximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        let tolerance: CGFloat = 0.002
        return abs(lhs.minX - rhs.minX) <= tolerance
            && abs(lhs.minY - rhs.minY) <= tolerance
            && abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }
}
