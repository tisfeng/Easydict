//
//  IndentationType.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - IndentationInfo

/// A structure containing the results of indentation analysis between two text observations.
struct IndentationInfo: CustomStringConvertible {
    /// The detected indentation type (positive, negative, or none).
    let indentationType: IndentationType

    /// The character difference in X position between the observations.
    let characterDifference: Double

    /// The base threshold used for indentation detection.
    let baseThreshold: Double

    /// The final threshold after applying confidence multiplier.
    let finalThreshold: Double

    /// The confidence level used in the analysis.
    let confidence: ConfidenceLevel

    /// The type of X comparison performed.
    let xComparison: XComparisonType

    /// A formatted string description of the analysis for debugging.
    var description: String {
        "IndentationType: \(indentationType), CharDiff: \(characterDifference.string1f), Threshold: \(finalThreshold.string1f) (base: \(baseThreshold) × \(confidence.multiplier)), Comparison: \(xComparison)"
    }

    /// Whether the detected indentation matches the requested type.
    func matches(_ requestedType: IndentationType) -> Bool {
        indentationType == requestedType
    }
}

// MARK: - IndentationType

/// Represents the type of indentation analysis to perform.
enum IndentationType {
    /// Check for positive indentation (text moves to the right)
    case positive
    /// Check for negative indentation (text moves to the left)
    case negative
    /// No indentation (text is aligned)
    case none

    // MARK: Internal

    /// Returns true if this indentation type considers direction.
    var isDirectional: Bool {
        switch self {
        case .negative, .positive: return true
        case .none: return false
        }
    }
}

// MARK: - XComparisonType

/// Represents the type of X position comparison for text observations.
enum XComparisonType {
    case minX
    case maxX
    case centerX
}
