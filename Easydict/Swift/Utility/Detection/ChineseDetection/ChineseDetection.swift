//
//  ChineseDetection.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - ChineseDetection

class ChineseDetection {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(text: String) {
        self.originalText = text
    }

    // MARK: Internal

    // MARK: - String Extensions

    let originalText: String

    // MARK: - Public Methods

    /// Detect the type of Chinese text and return analysis result
    func detect() -> ChineseAnalysis {
        logInfo("\nStarting Chinese text detection...")

        if let analysis {
            return analysis
        }

        let lines = splitTextIntoLines(originalText)
        let analysis = analyzeStructure(lines)

        // Determine text genre
        let detectedGenre: ChineseAnalysis.Genre
        if analysis.hasHighModernChineseMarkerRatio() {
            detectedGenre = .modern
        } else if isClassicalPoetry(analysis) {
            detectedGenre = .poetry
        } else if isClassicalLyrics(analysis) {
            detectedGenre = .lyric
        } else if isClassicalProse(analysis) {
            detectedGenre = .prose
        } else {
            detectedGenre = .modern
        }

        let result = analysis.with(genre: detectedGenre)
        self.analysis = result
        return result
    }

    /// Compare structural patterns between two lines including punctuation.
    /// Particularly useful for analyzing parallel structures in classical Chinese poetry and prose.
    ///
    /// Example:
    /// ```
    /// 十里青山远，潮平路带沙。数声啼鸟怨年华。又是凄凉时候、在天涯。
    /// 白露收残暑，清风衬晚霞。绿杨堤畔问荷花。记得年时沽酒、那人家。
    /// ```
    /// - Parameters:
    ///   - line1: First line to compare
    ///   - line2: Second line to compare
    /// - Returns: Structural similarity score (0.0 to 1.0)
    func compareStructuralPatterns(_ line1: String, _ line2: String) -> Double {
        let minCount = min(line1.count, line2.count)
        let maxCount = max(line1.count, line2.count)
        guard minCount > 0 else { return 0.0 }

        var matchCount = 0
        for i in 0 ..< minCount {
            let char1 = line1[line1.index(line1.startIndex, offsetBy: i)]
            let char2 = line2[line2.index(line2.startIndex, offsetBy: i)]
            // If both characters are not punctuation, count as a match
            if !char1.isPunctuation, !char2.isPunctuation {
                matchCount += 1
            }

            // If both characters are punctuation, and they are the same, count as a match
            if char1.isPunctuation, char2.isPunctuation, char1 == char2 {
                matchCount += 1
            }
        }

        return Double(matchCount) / Double(maxCount)
    }

    /// Split text into lines with separators.
    /// - Parameters:
    ///   - text: Input text to split
    ///   - separators: Additional separators to split lines, default is "\n".
    /// - Returns: Array of lines
    ///
    /// - Note:
    /// If the text contains only one line, split it with "。"
    func splitTextIntoLines(
        _ text: String,
        separators: [String] = ["\n"],
        omittingEmptySubsequences: Bool = true
    )
        -> [String] {
        let lines = splitIntoShortPhrases(text, separators: separators)

        // If only one line, try to split it with "。"
        if lines.count == 1, let singleLine = lines.first {
            return splitIntoShortPhrases(singleLine, separators: ["。"])
        }

        return lines
    }

    /// Split a string into phrases using specified separators.
    /// Used to analyze the internal structure of classical Chinese text.
    /// - Parameters:
    ///   - line: Input string to split
    ///   - separators: Array of separator strings, defaults to classical Chinese punctuation
    /// - Returns: Array of non-empty phrases with whitespace trimmed
    func splitIntoShortPhrases(
        _ line: String,
        separators: [String] = ChinseseMarker.Common.lineSeparators,
        omittingEmptySubsequences: Bool = true
    )
        -> [String] {
        var phrases = [line]
        for separator in separators {
            phrases = phrases.flatMap { $0.components(separatedBy: separator) }
        }

        phrases = phrases.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if omittingEmptySubsequences {
            phrases = phrases.filter { !$0.isEmpty }
        }
        return phrases
    }

    /// Check if line only contains meta punctuation marks in metadata
    func hasOnlyMetaPunctuation(_ line: String) -> Bool {
        !line.contains { char in
            let charStr = String(char)
            return charStr.rangeOfCharacter(from: .punctuationCharacters) != nil
                && !ChinseseMarker.Common.metaPunctuationCharacters.contains(charStr)
        }
    }

    /// Remove metadata with title index and author index
    /// - Parameters:
    ///  - lines: Array of text lines
    ///  - titleIndex: Index of title line, if found, titleIndex is first two lines index, or last two lines index
    ///  -  authorIndex: Index of author line, if found, authorIndex is first two lines index, or last two lines index
    func removeMetadataLines(
        from lines: [String],
        titleIndex: Int?,
        authorIndex: Int?
    )
        -> [String] {
        guard lines.count >= 2 else { return lines }

        var removedIndices: [Int] = []
        if let titleIndex {
            removedIndices.append(titleIndex)
        }

        if let authorIndex {
            removedIndices.append(authorIndex)
        }

        // Remove metadata lines
        return lines.enumerated().filter { index, _ in
            !removedIndices.contains(index)
        }.map { $0.element }
    }

    /// Find title and author in classical Chinese text
    /// - Parameter lines: Array of text lines
    /// - Returns: Metadata information containing title, author, dynasty and their indices
    func findTitleAndAuthor(in lines: [String]) -> ChineseAnalysis.Metadata {
        guard lines.count >= 2 else {
            return ChineseAnalysis.Metadata(
                title: nil, author: nil, dynasty: nil, titleIndex: nil, authorIndex: nil
            )
        }

        var titleIndex: Int?
        var authorIndex: Int?
        var title: String?
        var author: String?
        var dynasty: String?

        // Check each metadata line
        let linesToCheck = [
            (lines[0], 0), // First line
            lines.count >= 2 ? (lines[1], 1) : nil, // Second line
            lines.count >= 3 ? (lines[lines.count - 2], lines.count - 2) : nil, // Second to last line
            (lines[lines.count - 1], lines.count - 1), // Last line
        ].compactMap { $0 }

        for (line, index) in linesToCheck where isTitleOrAuthorLine(line) {
            let extractor = MetadataExtractor(line: line, index: index)
            let metadata = extractor.extract()

            // Found new title
            if title == nil, let extractedTitle = metadata.title {
                title = extractedTitle
                titleIndex = index
            }

            // Found new author or dynasty
            if author == nil || dynasty == nil {
                if let extractedAuthor = metadata.author {
                    author = extractedAuthor
                    authorIndex = index
                }
                if dynasty == nil {
                    dynasty = metadata.dynasty
                }
            }
        }

        return ChineseAnalysis.Metadata(
            title: title,
            author: author,
            dynasty: dynasty,
            titleIndex: titleIndex,
            authorIndex: authorIndex
        )
    }

    /// Check if a line could be a title or author line based on length and punctuation
    func isTitleOrAuthorLine(_ line: String) -> Bool {
        // Title/Author lines should be relatively short
        guard line.count <= 20 else { return false }

        // Should only contain allowed punctuation
        return hasOnlyMetaPunctuation(line)
    }

    /// Analyze the structure and return analysis result
    func analyzeStructure(_ lines: [String]) -> ChineseAnalysis {
        // Extract metadata
        let metadata = findTitleAndAuthor(in: lines)

        // Extract content without metadata
        let content = removeMetadataLines(
            from: lines,
            titleIndex: metadata.titleIndex,
            authorIndex: metadata.authorIndex
        ).joined(separator: "\n")

        // Count characters and punctuation
        let totalCount = content.count
        let punctCount = content.filter { $0.isPunctuation }.count
        let punctRatio = Double(punctCount) / Double(totalCount)

        // Analyze parallel structure
        let contentLines = splitTextIntoLines(content)
        var parallelCount = 0
        var totalComparisons = 0

        for i in 0 ..< contentLines.count - 1 {
            let similarity = compareStructuralPatterns(contentLines[i], contentLines[i + 1])
            if similarity >= 0.9 {
                parallelCount += 1
            }
            totalComparisons += 1
        }

        let parallelRatio =
            totalComparisons > 0 ? Double(parallelCount) / Double(totalComparisons) : 0.0

        // Analyze phrases
        let phrases = splitIntoShortPhrases(content)
        let phraseLengths = phrases.map { $0.filter { !$0.isWhitespace }.count }

        let avgLength = Double(phraseLengths.reduce(0, +)) / Double(phraseLengths.count)
        let maxLength = phraseLengths.max() ?? 0
        let minLength = phraseLengths.min() ?? 0
        let isUniform = Set(phraseLengths).count == 1

        let phraseAnalysis = ChineseAnalysis.PhraseAnalysis(
            averageLength: avgLength,
            maxLength: maxLength,
            minLength: minLength,
            isUniformLength: isUniform,
            phrases: phrases
        )

        let textCount = phraseLengths.reduce(0, +)

        return ChineseAnalysis(
            originalText: originalText,
            content: content,
            metadata: metadata,
            phraseAnalysis: phraseAnalysis,
            genre: .modern, // Default genre, will be updated later
            lines: contentLines,
            textCharCount: textCount,
            punctuationCount: punctCount,
            punctuationRatio: punctRatio,
            parallelStructureRatio: parallelRatio,
            classicalChineseRatio: content.calculateClassicalChineseMarkerRatio(),
            modernChineseRatio: content.calculateModernChineseMarkerRatio()
        )
    }

    // MARK: Private

    private var analysis: ChineseAnalysis?
}
