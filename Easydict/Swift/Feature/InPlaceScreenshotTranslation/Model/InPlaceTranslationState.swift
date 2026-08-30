//
//  InPlaceTranslationState.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - InPlaceTranslationLifecycle

/// Tracks the session lifecycle independently from processing progress.
enum InPlaceTranslationLifecycle: Equatable, Sendable {
    case selecting
    case starting
    case running
    case paused
    case stopping
    case stopped
}

// MARK: - InPlaceTranslationProcessingState

/// Reports user-visible progress for the latest valid generation.
enum InPlaceTranslationProcessingState: Equatable, Sendable {
    case idle
    case debouncing
    case recognizing(generation: UInt64)
    case translating(generation: UInt64, completed: Int, total: Int)
    case ready(generation: UInt64)
    case partialFailure(generation: UInt64, failed: Int, total: Int)
    case noText(generation: UInt64)
    case recoverableError(generation: UInt64?, category: InPlaceTranslationErrorCategory)
}

// MARK: - InPlaceTranslationCaptureAvailability

/// Separates transient system capture conditions from the main session lifecycle.
enum InPlaceTranslationCaptureAvailability: Equatable, Sendable {
    case available
    case sleeping
    case displayDisconnected
    case permissionDenied
    case temporarilyUnavailable
}

// MARK: - InPlaceTranslationRenderMode

/// Selects whether the canvas displays the source pixels or positioned translations.
enum InPlaceTranslationRenderMode: String, CaseIterable, Sendable {
    case original
    case translated
}

// MARK: - InPlaceTranslationErrorCategory

/// Sanitized product error categories that never include OCR text or credentials.
enum InPlaceTranslationErrorCategory: String, Equatable, Sendable {
    case capture
    case permission
    case displayDisconnected
    case noText
    case selectionTooLarge
    case serviceUnavailable
    case authentication
    case unsupportedLanguage
    case rateLimited
    case network
    case unknown
}

// MARK: - InPlaceTranslationConfiguration

/// Session-local languages plus durable defaults that affect live capture and the panel.
struct InPlaceTranslationConfiguration: @unchecked Sendable {
    var sourceLanguage: Language
    var targetLanguage: Language
    var serviceIdentifier: String
    var liveUpdatesEnabled: Bool
    var isPinned: Bool
    var renderMode: InPlaceTranslationRenderMode
}

// MARK: - InPlaceTranslationConstants

/// Central product limits for capture, OCR, translation concurrency, and live debouncing.
enum InPlaceTranslationConstants {
    static let samplingInterval: TimeInterval = 0.5
    static let debounceInterval: TimeInterval = 0.4
    static let maximumDebounceLatency: TimeInterval = 1.5
    static let minimumOCRInterval: TimeInterval = 1
    static let maximumBlockCount = 120
    static let maximumCharacterCount = 20_000
    static let maximumTranslationConcurrency = 3
    static let maximumCaptureLongEdge = 2_560
}

// MARK: - InPlaceGenerationGate

/// A monotonic token gate that makes stale asynchronous completion checks explicit.
struct InPlaceGenerationGate: Equatable, Sendable {
    private(set) var current: UInt64 = 0

    @discardableResult
    mutating func invalidate() -> UInt64 {
        current &+= 1
        return current
    }

    func accepts(_ generation: UInt64) -> Bool {
        generation == current
    }
}
