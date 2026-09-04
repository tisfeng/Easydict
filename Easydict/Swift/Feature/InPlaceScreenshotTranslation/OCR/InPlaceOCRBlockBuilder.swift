//
//  InPlaceOCRBlockBuilder.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Foundation

// MARK: - InPlaceOCRBlockBuilder

/// Groups immutable Vision observations into spatial section-level translation blocks.
/// The heuristic preserves columns by requiring nearby lines to overlap or align.
struct InPlaceOCRBlockBuilder: Sendable {
    // MARK: Lifecycle

    init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    // MARK: Internal

    /// Spatial thresholds for paragraph grouping.
    struct Configuration: Equatable, Sendable {
        // MARK: Lifecycle

        init(
            minimumHorizontalOverlapRatio: CGFloat = 0.2,
            maximumLeadingDifference: CGFloat = 0.08,
            maximumVerticalGapMultiplier: CGFloat = 1.8,
            minimumVerticalGap: CGFloat = 0.025
        ) {
            self.minimumHorizontalOverlapRatio = minimumHorizontalOverlapRatio
            self.maximumLeadingDifference = maximumLeadingDifference
            self.maximumVerticalGapMultiplier = maximumVerticalGapMultiplier
            self.minimumVerticalGap = minimumVerticalGap
        }

        // MARK: Internal

        let minimumHorizontalOverlapRatio: CGFloat
        let maximumLeadingDifference: CGFloat
        let maximumVerticalGapMultiplier: CGFloat
        let minimumVerticalGap: CGFloat
    }

    /// Builds reading-ordered blocks from one immutable layout result.
    func buildBlocks(from result: AppleOCRLayoutResult) -> [InPlaceOCRBlock] {
        let lines = result.observations
            .filter { !InPlaceTextNormalization.normalize($0.text).isEmpty }
            .map(Line.init)
            .sorted(by: Self.isOrderedBefore)

        var sections: [Section] = []
        for line in lines {
            let candidateIndex = sections.indices
                .filter { canAppend(line, to: sections[$0]) }
                .min { lhs, rhs in
                    appendScore(line, to: sections[lhs]) < appendScore(line, to: sections[rhs])
                }

            if let candidateIndex {
                sections[candidateIndex].append(line)
            } else {
                sections.append(Section(line: line))
            }
        }

        let languageDetector = AppleLanguageDetector()
        return sections
            .sorted { Self.isOrderedBefore($0.rect, $1.rect) }
            .enumerated()
            .map { index, section in
                let sourceText = section.lines.map(\.observation.text).joined(separator: "\n")
                return InPlaceOCRBlock(
                    id: section.lines.first?.observation.id ?? UUID(),
                    normalizedRect: section.rect,
                    quadrilateral: section.quadrilateral,
                    sourceText: sourceText,
                    detectedLanguage: languageDetector.detectLanguage(text: sourceText),
                    confidence: section.confidence,
                    readingOrder: index
                )
            }
    }

    // MARK: Private

    private let configuration: Configuration

    private static func isOrderedBefore(_ lhs: Line, _ rhs: Line) -> Bool {
        isOrderedBefore(lhs.rect, rhs.rect)
    }

    private static func isOrderedBefore(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        let sameRowTolerance = max(lhs.height, rhs.height) * 0.5
        if abs(lhs.minY - rhs.minY) <= sameRowTolerance {
            return lhs.minX < rhs.minX
        }
        return lhs.minY < rhs.minY
    }

    private func canAppend(_ line: Line, to section: Section) -> Bool {
        guard let lastLine = section.lines.last else { return false }
        let verticalGap = line.rect.minY - lastLine.rect.maxY
        let maximumGap = max(
            configuration.minimumVerticalGap,
            max(line.rect.height, lastLine.rect.height)
                * configuration.maximumVerticalGapMultiplier
        )
        guard verticalGap >= -min(line.rect.height, lastLine.rect.height) * 0.35,
              verticalGap <= maximumGap
        else {
            return false
        }

        let intersectionWidth = line.rect.intersection(section.rect).width
        let referenceWidth = max(0.000_1, min(line.rect.width, section.rect.width))
        let overlapRatio = max(0, intersectionWidth) / referenceWidth
        let leadingDifference = abs(line.rect.minX - lastLine.rect.minX)
        return overlapRatio >= configuration.minimumHorizontalOverlapRatio
            || leadingDifference <= configuration.maximumLeadingDifference
    }

    private func appendScore(_ line: Line, to section: Section) -> CGFloat {
        guard let lastLine = section.lines.last else { return .greatestFiniteMagnitude }
        let verticalGap = max(0, line.rect.minY - lastLine.rect.maxY)
        let horizontalDistance = abs(line.rect.midX - section.rect.midX)
        return verticalGap * 3 + horizontalDistance
    }
}

// MARK: - Line

/// A single Vision observation converted to the product coordinate system.
private struct Line: Sendable {
    // MARK: Lifecycle

    init(observation: AppleOCRLayoutObservation) {
        self.observation = observation
        self.rect = OCRImageGeometry.topLeftNormalizedRect(
            fromVisionRect: observation.visionNormalizedRect
        )
        self.quadrilateral = InPlaceOCRQuadrilateral(
            topLeft: CGPoint(x: observation.topLeft.x, y: 1 - observation.topLeft.y),
            topRight: CGPoint(x: observation.topRight.x, y: 1 - observation.topRight.y),
            bottomRight: CGPoint(x: observation.bottomRight.x, y: 1 - observation.bottomRight.y),
            bottomLeft: CGPoint(x: observation.bottomLeft.x, y: 1 - observation.bottomLeft.y)
        )
    }

    // MARK: Internal

    let observation: AppleOCRLayoutObservation
    let rect: CGRect
    let quadrilateral: InPlaceOCRQuadrilateral
}

// MARK: - Section

/// Mutable construction state for one section-level block.
private struct Section: Sendable {
    // MARK: Lifecycle

    init(line: Line) {
        self.lines = [line]
        self.rect = line.rect
    }

    // MARK: Internal

    private(set) var lines: [Line]
    private(set) var rect: CGRect

    var confidence: Float {
        guard !lines.isEmpty else { return 0 }
        return lines.reduce(0) { $0 + $1.observation.confidence } / Float(lines.count)
    }

    var quadrilateral: InPlaceOCRQuadrilateral? {
        lines.count == 1 ? lines[0].quadrilateral : nil
    }

    mutating func append(_ line: Line) {
        lines.append(line)
        rect = rect.union(line.rect)
    }
}
