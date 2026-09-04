//
//  InPlaceOCRPipeline.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - OCRLayoutRecognizing

/// Product boundary for local, immutable, layout-preserving OCR.
protocol OCRLayoutRecognizing: Sendable {
    func recognizeLayout(image: CGImage, language: Language) async throws -> AppleOCRLayoutResult
}

// MARK: - AppleInPlaceOCRLayoutRecognizer

/// Adapts AppleOCREngine's in-memory layout API to the live session protocol.
struct AppleInPlaceOCRLayoutRecognizer: OCRLayoutRecognizing, Sendable {
    func recognizeLayout(image: CGImage, language: Language) async throws -> AppleOCRLayoutResult {
        let nsImage = NSImage(cgImage: image, size: .zero)
        return try await AppleOCREngine().recognizeLayout(image: nsImage, language: language)
    }
}

// MARK: - InPlaceOCRPipelineResult

/// Immutable section blocks and detected language from one OCR generation.
struct InPlaceOCRPipelineResult: Sendable {
    let blocks: [InPlaceOCRBlock]
    let detectedLanguage: Language
    let characterCount: Int
}

// MARK: - InPlaceOCRPipelineError

/// Safety-limit failures that prevent unbounded automatic provider requests.
enum InPlaceOCRPipelineError: Error, Equatable, Sendable {
    case tooManyBlocks(Int)
    case tooManyCharacters(Int)
}

// MARK: - InPlaceOCRPipeline

/// Runs local layout OCR, builds section blocks, and enforces per-session request limits.
struct InPlaceOCRPipeline: Sendable {
    // MARK: Lifecycle

    init(
        recognizer: any OCRLayoutRecognizing = AppleInPlaceOCRLayoutRecognizer(),
        blockBuilder: InPlaceOCRBlockBuilder = .init()
    ) {
        self.recognizer = recognizer
        self.blockBuilder = blockBuilder
    }

    // MARK: Internal

    func recognize(image: CGImage, language: Language) async throws -> InPlaceOCRPipelineResult {
        let result = try await recognizer.recognizeLayout(image: image, language: language)
        let blocks = blockBuilder.buildBlocks(from: result)
        guard blocks.count <= InPlaceTranslationConstants.maximumBlockCount else {
            throw InPlaceOCRPipelineError.tooManyBlocks(blocks.count)
        }
        let characterCount = blocks.reduce(0) { $0 + $1.sourceText.count }
        guard characterCount <= InPlaceTranslationConstants.maximumCharacterCount else {
            throw InPlaceOCRPipelineError.tooManyCharacters(characterCount)
        }
        return InPlaceOCRPipelineResult(
            blocks: blocks,
            detectedLanguage: result.detectedLanguage,
            characterCount: characterCount
        )
    }

    // MARK: Private

    private let recognizer: any OCRLayoutRecognizing
    private let blockBuilder: InPlaceOCRBlockBuilder
}
