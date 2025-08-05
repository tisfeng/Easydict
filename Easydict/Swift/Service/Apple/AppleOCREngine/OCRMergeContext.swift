//
//  OCRMergeContext.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

/// A context object that encapsulates commonly used variables and calculations
/// for OCR text merging strategies, reducing code duplication.
struct OCRMergeContext {
    // MARK: Lifecycle

    init(
        pair: OCRTextObservationPair,
        maxXObservation: VNRecognizedTextObservation,
        paragraphObservations: [VNRecognizedTextObservation],
        metrics: OCRMetrics
    ) {
        self.pair = pair
        self.maxXObservation = maxXObservation
        self.paragraphObservations = paragraphObservations
        self.metrics = metrics

        self.lineAnalyzer = OCRLineAnalyzer(metrics: metrics)
        self.dashHandler = OCRDashHandler(metrics: metrics)
    }

    // MARK: Internal

    // MARK: - Indentation Properties

    lazy var isFirstHasIndentation: Bool = {
        guard let first = firstObservation else { return false }
        return lineAnalyzer.hasIndentation(observation: first)
    }()

    lazy var isPrevHasIndentation: Bool = {
        guard let first = firstObservation else { return false }
        return (previous == first)
            ? isFirstHasIndentation : lineAnalyzer.hasIndentation(observation: previous)
    }()

    lazy var isEqualPairX: Bool = {
        lineAnalyzer.isEqualX(pair: pair)
    }()

    lazy var hasBigDifferentX: Bool = {
        !lineAnalyzer.hasNoIndentation(observation: current, compared: previous, confidence: .high)
    }()

    lazy var hasBigIndentation: Bool = {
        lineAnalyzer.hasIndentation(observation: current, compared: previous, confidence: .high)
    }()

    lazy var hasPairIndentation: Bool = {
        lineAnalyzer.hasIndentation(observation: current, compared: previous)
    }()

    lazy var hasIndentation: Bool = {
        lineAnalyzer.hasIndentation(observation: current)
    }()

    // MARK: - Line Spacing Properties

    lazy var hasBigLineSpacing: Bool = {
        lineAnalyzer.isBigLineSpacing(pair: pair)
    }()

    lazy var hasVeryBigLineSpacing: Bool = {
        lineAnalyzer.isBigLineSpacing(pair: pair, confidence: .high)
    }()

    lazy var hasBigLineSpacingRelaxed: Bool = {
        lineAnalyzer.isBigLineSpacing(pair: pair, confidence: .low)
    }()

    // MARK: - Font Size Properties

    lazy var hasDifferentFontSize: Bool = {
        lineAnalyzer.hasDifferentFontSize(pair: pair)
    }()

    lazy var hasBigDifferentFontSize: Bool = {
        lineAnalyzer.hasDifferentFontSize(pair: pair, confidence: .custom(2.0))
    }()

    lazy var hasDifferentFontSizeRelaxed: Bool = {
        lineAnalyzer.hasDifferentFontSize(pair: pair, confidence: .low)
    }()

    lazy var isEqualPairCenterX: Bool = {
        lineAnalyzer.isEqualCenterX(pair: pair)
    }()

    // MARK: - Text Length Properties

    lazy var comparedObservation: VNRecognizedTextObservation = {
        isFirstHasIndentation ? maxXObservation : metrics.maxXObservation!
    }()

    lazy var isPreviousLongText: Bool = {
        lineAnalyzer.isLongText(
            observation: previous,
            nextObservation: current,
            comparedObservation: comparedObservation
        )
    }()

    lazy var distanceXRatio: Double = {
        let dx = previous.boundingBox.minX - current.boundingBox.minX
        return dx / metrics.maxLineLength
    }()

    lazy var isPrevAbsoluteLongText: Bool = {
        lineAnalyzer.isLongText(observation: previous, nextObservation: current)
    }()

    lazy var isShortLine: Bool = {
        lineAnalyzer.isShortLine(observation: current)
    }()

    lazy var isPreviousShortLine: Bool = {
        lineAnalyzer.isShortLine(observation: previous)
    }()

    // MARK: - Content Type Properties

    lazy var isCurrentList: Bool = {
        currentText.hasListPrefix
    }()

    lazy var isPreviousList: Bool = {
        previousText.hasListPrefix
    }()

    lazy var isFirstObservationList: Bool = {
        firstObservation?.firstText.hasListPrefix ?? false
    }()

    // MARK: - Text Analysis Properties

    lazy var previousTextHasEndPunctuation: Bool = {
        previousText.hasEndPunctuationSuffix
    }()

    lazy var isFirstCharLowercase: Bool = {
        currentText.isFirstCharLowercase
    }()

    // MARK: - Special Analysis Properties

    lazy var isEqualChinesePair: Bool = {
        lineAnalyzer.isEqualChinesePair(pair)
    }()

    lazy var isPoetry: Bool = {
        metrics.isPoetry
    }()

    lazy var isClassicalChinese: Bool = {
        metrics.language == .classicalChinese
    }()

    // MARK: - Comparative Properties

    lazy var isEqualFirstLineX: Bool = {
        guard let first = firstObservation else { return false }
        let firstPair = OCRTextObservationPair(current: current, previous: first)
        return lineAnalyzer.isEqualX(pair: firstPair)
    }()

    // MARK: - Combined Logic Properties

    lazy var mayBeNewParagraph: Bool = {
        // Different font size may be not precise, so use a medium threshold
        hasBigLineSpacingRelaxed || hasDifferentFontSize
    }()

    let pair: OCRTextObservationPair

    var isNewLine: Bool {
        lineAnalyzer.isNewLine(pair: pair)
    }

    var current: VNRecognizedTextObservation {
        pair.current
    }

    var previous: VNRecognizedTextObservation {
        pair.previous
    }

    var currentText: String {
        current.firstText
    }

    var previousText: String {
        previous.firstText
    }

    var firstObservation: VNRecognizedTextObservation? {
        paragraphObservations.first
    }

    var dashMergeStrategy: OCRMergeStrategy? {
        dashHandler.dashMergeStrategy(pair)
    }

    // MARK: Private

    private let metrics: OCRMetrics
    private let maxXObservation: VNRecognizedTextObservation
    private let paragraphObservations: [VNRecognizedTextObservation]

    private let lineAnalyzer: OCRLineAnalyzer
    private let dashHandler: OCRDashHandler
}
