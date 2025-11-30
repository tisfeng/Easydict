//
//  String+Constants.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - QueryTextType

/// Query text type for determining how to handle text input
typealias QueryTextType = EZQueryTextType

// MARK: - Constants

extension String {
    /// Point characters for list detection
    static let pointCharacters = ["•", "‧", "∙"]

    /// Dash characters for list detection
    static let dashCharacters = ["—", "-", "–"]

    /// End punctuation marks
    static let endPunctuationMarks = ["。", "？", "！", "?", "!", ";", ":", "：", "...", "……"]

    /// Quote pairs for matching
    static let quotePairs: [String: String] = [
        "\"": "\"",
        "'": "'",
        "`": "`",
        "“": "”",
        "‘": "’",
        "«": "»",
        "‹": "›",
        "「": "」",
        "『": "』",
        "《": "》",
        "〈": "〉",
        "﹁": "﹂",
        "﹃": "﹄",
    ]

    /// Maximum English word length for dictionary lookup
    static let englishWordMaxLength = 20
}

// MARK: - EZ Point and Dash Character Lists (Objective-C Compatibility)

/// Point character list for Objective-C compatibility
let EZPointCharacterList: [String] = String.pointCharacters
