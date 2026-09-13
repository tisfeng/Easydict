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
    static let endPunctuationMarks = [
        ".", "。", "?", "？", "!", "！", ";", ":", "：", "..", "...", "…", "……",
    ]

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

    /// Maximum Japanese word length (in characters) for dictionary lookup.
    ///
    /// Japanese has no word boundaries and `NLTokenizer` splits compound words
    /// (見つめ直す → 見つめ / 直す), so a character limit is used instead of a
    /// word count, see `isJapaneseWord`.
    static let japaneseWordMaxLength = 8

    /// Japanese case and topic particles. A short text whose tokens include one
    /// of these is a clause (彼は来た), not a dictionary word.
    static let japaneseParticles: Set<String> = [
        "は", "が", "を", "に", "へ", "で", "と", "も", "から", "まで", "より",
    ]

    /// Endings that close a Japanese sentence: a copula (私は学生です, お元気ですか,
    /// 学生でした), or a polite verb followed by a final particle (行きますか).
    /// A polite verb on its own (行きます) is not matched, because it is a single
    /// conjugated word and dictionary lookup resolves it to its dictionary form.
    static let japaneseSentenceEndingPattern =
        "(です|でした|でしょう)[かねよ]*$|(ます|ました|ません|ましょう|ください)[かねよ]+$"
}

// MARK: - EZ Point and Dash Character Lists (Objective-C Compatibility)

/// Point character list for Objective-C compatibility
let EZPointCharacterList: [String] = String.pointCharacters
