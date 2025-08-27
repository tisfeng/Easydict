//
//  ConfidenceLevel.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - ConfidenceLevel

/// Defines various confidence levels for OCR analysis thresholds.
///
/// These levels adjust detection thresholds to provide more or less strict analysis
/// depending on the reliability of the OCR data and specific use cases.
enum ConfidenceLevel {
    /// High confidence level, applies a 1.5x multiplier to thresholds (more strict).
    case high
    /// Medium confidence level, applies a 1.0x multiplier to thresholds (default).
    case medium
    /// Low confidence level, applies a 0.7x multiplier to thresholds (more lenient).
    case low
    /// Custom confidence level, allows a user-defined multiplier.
    case custom(Double)

    // MARK: Lifecycle

    /// Initializes a custom confidence level with a specific multiplier value.
    /// - Parameter multiplier: The exact threshold multiplier value to use.
    init(multiplier: Double) {
        self = .custom(multiplier)
    }

    // MARK: Internal

    /// The numerical multiplier associated with the confidence level.
    var multiplier: Double {
        switch self {
        case .high: return 1.5
        case .medium: return 1.0
        case .low: return 0.7
        case let .custom(multiplier): return multiplier
        }
    }
}
