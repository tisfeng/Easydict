//
//  ChineseDetection.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
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

    var analysis: ChineseAnalysis?

    /// Minimum length for classical Chinese text detection, default is 10
    var minClassicalChineseTextDetectLength: Int {
        let minLength = 10
        let length = Int(Defaults[.minClassicalChineseTextDetectLength]) ?? minLength
        return max(length, minLength)
    }

    // MARK: - Public Methods

    /// Detect the type of Chinese text and return analysis result
    func detect() -> ChineseAnalysis {
        logInfo("\nStarting Chinese text detection...")

        // Return cached analysis if available
        if let existingAnalysis = analysis {
            logInfo("Returning cached analysis.")
            return existingAnalysis
        }

        let newAnalysis = analyzeStructure(originalText)
        log("Text analysis: \(newAnalysis.prettyJSONString)")

        // Check if the text is too short for classical Chinese detection
        guard newAnalysis.textInfo.characterCount >= minClassicalChineseTextDetectLength else {
            logInfo(
                "Text count (\(newAnalysis.textInfo.characterCount)) is less than \(minClassicalChineseTextDetectLength), skipping classical detection."
            )
            newAnalysis.genre = .modern
            analysis = newAnalysis
            return newAnalysis
        }

        // Determine and set text genre based on analysis
        newAnalysis.genre = determineGenre(for: newAnalysis)

        analysis = newAnalysis
        return newAnalysis
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
    func findTitleAndAuthor(in lines: [String]) -> ChineseAnalysis.Metadata? {
        guard lines.count >= 2 else { return nil }

        /**
         If lines have no punctuation, it is likely a prose text.

         我本可以忍受黑暗
         如果我不曾见过太阳
         然而阳光已使我的荒凉
         成为更新的荒凉
         */
        let punctInfo = analyzePunctuation(lines.joined())
        if punctInfo.isEmpty, !lines[1].isEmpty {
            return nil
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
    func analyzeStructure(_ text: String) -> ChineseAnalysis {
        // Split text into lines and analyze metadata
        let lines = text.splitTextIntoLines()
        let metadata = findTitleAndAuthor(in: lines)

        // Determine content lines by removing metadata if found
        var contentLines = lines
        if let metadata {
            contentLines = removeMetadataLines(
                from: lines,
                titleIndex: metadata.titleIndex,
                authorIndex: metadata.authorIndex
            )
        }

        let content = contentLines.joined(separator: "\n")
        let nonEmptyLines = contentLines.filter { !$0.isEmpty }

        // Analyze text components
        let phraseInfo = analyzePhraseStructure(nonEmptyLines)
        let punctInfo = analyzePunctuation(content)
        let lingInfo = analyzeLinguisticFeatures(content)

        // Calculate character count from phrases
        let characterCount = phraseInfo.phrases.reduce(0) {
            $0 + $1.filter { !$0.isWhitespace }.count
        }

        let textInfo = ChineseAnalysis.TextInfo(
            rawText: text,
            processedText: content,
            lines: lines,
            characterCount: characterCount
        )

        return ChineseAnalysis(
            textInfo: textInfo,
            metadata: metadata,
            phraseInfo: phraseInfo,
            punctInfo: punctInfo,
            lingInfo: lingInfo
        )
    }

    // MARK: Private

    /// Analyze punctuation statistics in text
    /// - Parameter text: Input text to analyze
    /// - Returns: Punctuation statistics
    private func analyzePunctuation(_ text: String) -> ChineseAnalysis.PunctuationInfo {
        let totalCount = text.count
        let punctCount = text.filter { $0.isPunctuation }.count
        let punctRatio = Double(punctCount) / Double(totalCount)

        return ChineseAnalysis.PunctuationInfo(
            count: punctCount,
            ratio: punctRatio
        )
    }

    /// Determine the genre of the text based on analysis results
    private func determineGenre(for analysis: ChineseAnalysis) -> ChineseAnalysis.Genre {
        if analysis.lingInfo.hasHighModernRatio() {
            return .modern
        }
        if isClassicalPoetry(analysis) {
            return .poetry
        }
        if isClassicalLyrics(analysis) {
            return .lyric
        }
        if isClassicalProse(analysis) {
            return .prose
        }
        return .modern // Default to modern if no classical type matches
    }

    /// Analyze linguistic features (classical/modern ratios)
    private func analyzeLinguisticFeatures(_ text: String) -> ChineseAnalysis.LinguisticInfo {
        ChineseAnalysis.LinguisticInfo(
            classicalRatio: text.calculateClassicalChineseMarkerRatio(),
            modernRatio: text.calculateModernChineseMarkerRatio()
        )
    }

    /// Analyze phrase structure including parallel structure and phrase lengths
    /// - Parameters:
    ///   - contentLines: Array of content lines, excluding metadata and empty lines
    ///   - Returns: Phrase analysis result
    private func analyzePhraseStructure(_ contentLines: [String]) -> ChineseAnalysis.PhraseInfo {
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

        let phrases = contentLines.joined(separator: "\n").splitIntoShortPhrases()
        let phraseLengths = phrases.map { $0.filter { !$0.isWhitespace }.count }

        // Guard against division by zero if there are no phrases
        let avgLength =
            phraseLengths.isEmpty
                ? 0.0 : Double(phraseLengths.reduce(0, +)) / Double(phraseLengths.count)
        let maxLength = phraseLengths.max() ?? 0
        let minLength = phraseLengths.min() ?? 0
        let isUniform = Set(phraseLengths).count == 1

        return ChineseAnalysis.PhraseInfo(
            phrases: phrases,
            averageLength: avgLength,
            maxLength: maxLength,
            minLength: minLength,
            isUniformLength: isUniform,
            parallelRatio: parallelRatio
        )
    }
}
