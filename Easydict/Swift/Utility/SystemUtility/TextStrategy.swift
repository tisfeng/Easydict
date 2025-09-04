//
//  TextStrategy.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/4.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - TextStrategy

/// Text retrieval strategies
@objc(EZTextStrategy)
enum TextStrategy: Int, CaseIterable {
    case accessibility = 0
    case appleScript = 1
    case shortcut = 2
    case menuAction = 3

    // MARK: Internal

    var description: String {
        switch self {
        case .accessibility:
            return "Accessibility API"
        case .appleScript:
            return "AppleScript"
        case .shortcut:
            return "Keyboard Shortcut"
        case .menuAction:
            return "Menu Action"
        }
    }
}

// MARK: - TextStrategy

typealias TextStrategySet = Set<TextStrategy>

// MARK: - TextOperationSet Extensions

extension Set where Element == TextStrategy {
    /// Create a set with a single operation type
    static func single(_ type: TextStrategy) -> TextStrategySet {
        [type]
    }

    /// Create a set with multiple operation types
    static func multiple(_ types: TextStrategy...) -> TextStrategySet {
        Set(types)
    }

    /// Common operation sets for convenience
    static let all: TextStrategySet = Set(TextStrategy.allCases)
    static let preferred: TextStrategySet = [.appleScript, .accessibility]
    static let fallback: TextStrategySet = [.shortcut]
}
