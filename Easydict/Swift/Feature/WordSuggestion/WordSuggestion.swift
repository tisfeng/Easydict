//
//  WordSuggestion.swift
//  Easydict
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - WordSuggestion

/// One row in the word suggestion list shown under the query input.
struct WordSuggestion: Equatable {
    /// Why the word was suggested.
    enum Origin: Equatable {
        /// Spelled like the input: a correction or a completion.
        case similar
        /// Shares a root with the input but has another part of speech.
        case related
    }

    let word: String
    var partOfSpeech: String?
    var meaning: String?
    let origin: Origin
}

// MARK: - WordDefinition

/// A short dictionary gloss: the first part of speech and its main meaning.
struct WordDefinition: Equatable, Sendable {
    let partOfSpeech: String?
    let meaning: String
}
