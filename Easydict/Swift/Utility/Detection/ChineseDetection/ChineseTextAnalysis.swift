//
//  ChineseTextAnalysis.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - ChineseTextAnalysis

/// Analysis result for Chinese text detection
struct ChineseTextAnalysis {
    // Content structure analysis
    let contentInfo: ContentInfo

    // Basic text info
    let originalText: String
    let lines: [String]
    let content: String

    // Metadata
    let title: String?
    let author: String?
    let dynasty: String?

    // Location info of metadata
    let titleIndex: Int?
    let authorIndex: Int?

    // Detection result
    let genre: Genre
}

// MARK: - ContentInfo

/// Structure to store content analysis information
struct ContentInfo {
    /// Phrase analysis after splitting by punctuation
    struct PhraseAnalysis {
        let averageLength: Double
        let maxLength: Int
        let minLength: Int
        let isUniformLength: Bool
        let phrases: [String]
    }

    /// Phrase analysis
    let phraseAnalysis: PhraseAnalysis

    /// Contnet text
    let text: String

    /// Content lines
    let lines: [String]

    /// Character count excluding punctuation
    let textCharCount: Int

    /// Count of punctuation marks
    let punctuationCount: Int

    /// Ratio of punctuation marks to total characters
    let punctuationRatio: Double

    /// Parallel structure ratio between adjacent lines
    let parallelStructureRatio: Double

    /// Ratio of classical Chinese characters
    let classicalChineseRatio: Double

    /// Ratio of modern Chinese characters
    let modernChineseRatio: Double

    /// Has high classical Chinese marker ratio, threshold is 0.15
    func hasHighClassicalChineseMarkerRatio(_ threshold: Double = 0.15) -> Bool {
        classicalChineseRatio >= threshold
    }

    /// Has high modern Chinese marker ratio, threshold is 0.2
    func hasHighModernChineseMarkerRatio(_ threshold: Double = 0.2) -> Bool {
        modernChineseRatio >= threshold
    }
}

// MARK: - Genre

/// The type of classical text
/// - `prose`: Classical prose 古文
/// - `poetry`: Classical poetry 古诗
/// - `lyric`: Classical lyric 古词
/// - `modern`: Modern Chinese 现代汉语
enum Genre {
    case prose
    case poetry
    case lyric
    case modern
}
