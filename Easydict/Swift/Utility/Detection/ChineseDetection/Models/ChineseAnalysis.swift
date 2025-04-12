//
//  ChineseAnalysis.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - ChineseAnalysis

/// Analysis result for Chinese text detection
class ChineseAnalysis: Codable {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(
        textInfo: TextInfo,
        metadata: Metadata?,
        phraseInfo: PhraseInfo,
        punctInfo: PunctuationInfo,
        lingInfo: LinguisticInfo,
        genre: Genre = .modern
    ) {
        self.textInfo = textInfo
        self.metadata = metadata
        self.phraseInfo = phraseInfo
        self.punctInfo = punctInfo
        self.lingInfo = lingInfo
        self.genre = genre
    }

    // MARK: Internal

    // MARK: - Types

    /// Text content information
    struct TextInfo: Codable {
        /// Original text
        let rawText: String

        /// Content after metadata removal
        let processedText: String

        /// Content lines, including empty lines
        let lines: [String]

        /// Character count excluding punctuation
        let characterCount: Int
    }

    /// Punctuation statistics
    struct PunctuationInfo: Codable {
        let count: Int
        let ratio: Double

        var isEmpty: Bool {
            count == 0
        }
    }

    /// Linguistic feature ratios
    struct LinguisticInfo: Codable {
        enum CodingKeys: String, CodingKey {
            case classicalRatio
            case modernRatio
        }

        let classicalRatio: Double
        let modernRatio: Double

        func hasHighClassicalRatio(_ threshold: Double = 0.1) -> Bool {
            classicalRatio >= threshold
        }

        func hasHighModernRatio(_ threshold: Double = 0.1) -> Bool {
            modernRatio >= threshold
        }
    }

    /// Metadata information
    struct Metadata: Codable {
        let title: String?
        let author: String?
        let dynasty: String?
        let titleIndex: Int?
        let authorIndex: Int?
    }

    /// Phrase analysis information
    struct PhraseInfo: Codable {
        /// Phrase text removed punctuation
        let phrases: [String]
        let averageLength: Double
        let maxLength: Int
        let minLength: Int

        /// All phrases are the same length
        let isUniformLength: Bool

        /// Parallel structure ratio between adjacent lines
        let parallelRatio: Double
    }

    // MARK: - Genre

    /// The type of classical text
    /// - `prose`: Classical prose 古文
    /// - `poetry`: Classical poetry 古诗
    /// - `lyric`: Classical lyric 古词
    /// - `modern`: Modern Chinese 现代汉语
    enum Genre: String, Codable {
        case prose
        case poetry
        case lyric
        case modern
    }

    let textInfo: TextInfo
    let metadata: Metadata?
    let phraseInfo: PhraseInfo
    let punctInfo: PunctuationInfo
    let lingInfo: LinguisticInfo
    var genre: Genre = .modern
}
