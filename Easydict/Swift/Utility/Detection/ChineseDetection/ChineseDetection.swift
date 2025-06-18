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

    // MARK: Private

    /// Minimum length for classical Chinese text detection, default is 10
    private var minClassicalChineseTextDetectLength: Int {
        let minLength = 10
        let length = Int(Defaults[.minClassicalChineseTextDetectLength]) ?? minLength
        return max(length, minLength)
    }

    // MARK: - Structure Analysis Core

    /// Analyze the structure and return analysis result
    private func analyzeStructure(_ text: String) -> ChineseAnalysis {
        // 1. Split text into lines
        let lines = text.splitTextIntoLines()

        // 2. Find metadata (title, author, etc.)
        let metadata = findTitleAndAuthor(in: lines)

        // 3. Determine content lines by removing metadata if found
        let contentLines = determineContentLines(from: lines, metadata: metadata)
        let content = contentLines.joined(separator: "\n")
        let nonEmptyLines = contentLines.filter { !$0.isEmpty }

        // 4. Analyze text components
        let phraseInfo = analyzePhraseStructure(nonEmptyLines)
        let punctInfo = analyzePunctuation(content)
        let lingInfo = analyzeLinguisticFeatures(content)

        // 5. Calculate character count
        let characterCount = phraseInfo.phrases.reduce(0) {
            $0 + $1.filter { !$0.isWhitespace }.count
        }

        // 6. Create TextInfo
        let textInfo = ChineseAnalysis.TextInfo(
            rawText: text,
            processedText: content,
            lines: lines,
            characterCount: characterCount
        )

        // 7. Assemble final analysis object
        return ChineseAnalysis(
            textInfo: textInfo,
            metadata: metadata,
            phraseInfo: phraseInfo,
            punctInfo: punctInfo,
            lingInfo: lingInfo
        )
    }

    // MARK: - Metadata Analysis Helpers

    /// Find title and author in classical Chinese text
    /// - Parameter lines: Array of text lines
    /// - Returns: Metadata information containing title, author, dynasty and their indices
    private func findTitleAndAuthor(in lines: [String]) -> ChineseAnalysis.Metadata? {
        guard lines.count >= 2 else { return nil }

        // Skip metadata detection for prose-like text without punctuation early on
        let punctInfo = analyzePunctuation(lines.joined())
        if punctInfo.isEmpty, !lines[1].isEmpty {
            logInfo(
                "Skipping metadata detection: No punctuation found in early lines, likely prose."
            )
            return nil
        }

        var titleIndex: Int?
        var authorIndex: Int?
        var title: String?
        var author: String?
        var dynasty: String?

        // Check potential metadata lines (first 2, last 2)
        for (line, index) in potentialMetadataLines(from: lines) where isTitleOrAuthorLine(line) {
            let extractor = MetadataExtractor(line: line, index: index)
            let extracted = extractor.extract()

            // Assign found metadata components
            if title == nil, let extractedTitle = extracted.title {
                title = extractedTitle
                titleIndex = index
            }
            if author == nil, let extractedAuthor = extracted.author {
                author = extractedAuthor
                authorIndex = index // Use the same index if author/dynasty are on the same line
            }
            if dynasty == nil, let extractedDynasty = extracted.dynasty {
                dynasty = extractedDynasty
                if authorIndex == nil { authorIndex = index } // Ensure index is set if dynasty found first
            }
        }

        // Return nil if no actual metadata components were found
        guard title != nil || author != nil || dynasty != nil else {
            logInfo("No title, author, or dynasty found in potential metadata lines.")
            return nil
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
    private func isTitleOrAuthorLine(_ line: String) -> Bool {
        // If line starts with 《 and ends with 》, it's likely a title
        if line.hasPrefix("《"), line.hasSuffix("》") {
            return true
        }

        // Title/Author lines should be relatively short
        guard line.count <= 20 else { return false }

        // Should only contain allowed punctuation
        return hasOnlyMetaPunctuation(line)
    }

    /// Remove metadata lines based on provided indices
    private func removeMetadataLines(
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

    // MARK: - Utility Methods

    /// Compare structural patterns between two lines including punctuation.
    private func compareStructuralPatterns(_ line1: String, _ line2: String) -> Double {
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

    /// Check if line only contains meta punctuation marks allowed in metadata
    private func hasOnlyMetaPunctuation(_ line: String) -> Bool {
        !line.contains { char in
            let charStr = String(char)
            return charStr.rangeOfCharacter(from: .punctuationCharacters) != nil
                && !ChinseseMarker.Common.metaPunctuationCharacters.contains(charStr)
        }
    }

    /// Get potential metadata lines (first 2, last 2) from the text lines.
    private func potentialMetadataLines(from lines: [String]) -> [(String, Int)] {
        guard lines.count >= 1 else { return [] }
        var linesToCheck: [(String, Int)] = []
        linesToCheck.append((lines[0], 0)) // First line
        if lines.count >= 2 {
            linesToCheck.append((lines[1], 1)) // Second line
        }
        if lines.count >= 3 {
            linesToCheck.append((lines[lines.count - 2], lines.count - 2)) // Second to last line
        }
        if lines.count >= 2 { // Ensure last line is different from first if count is 1 or 2
            if lines.count > 1 || linesToCheck.first?.1 != lines.count - 1 {
                linesToCheck.append((lines[lines.count - 1], lines.count - 1)) // Last line
            }
        }
        // Remove duplicates just in case (e.g., for very short texts)
        return Array(Set(linesToCheck.map { "\($0.1)---\($0.0)" }))
            .compactMap { lineInfo -> (String, Int)? in
                let parts = lineInfo.split(separator: "---", maxSplits: 1)
                guard parts.count == 2, let index = Int(parts[0]) else { return nil }
                return (String(parts[1]), index)
            }
            .sorted { $0.1 < $1.1 } // Sort by index
    }

    /// Determine content lines by removing metadata if found
    private func determineContentLines(from lines: [String], metadata: ChineseAnalysis.Metadata?)
        -> [String] {
        guard let metadata = metadata else {
            return lines // No metadata found, return original lines
        }
        return removeMetadataLines(
            from: lines,
            titleIndex: metadata.titleIndex,
            authorIndex: metadata.authorIndex
        )
    }

    // MARK: - Content Analysis Helpers

    /// Analyze punctuation statistics in text
    private func analyzePunctuation(_ text: String) -> ChineseAnalysis.PunctuationInfo {
        let totalCount = text.count
        let punctCount = text.filter { $0.isPunctuation }.count
        let punctRatio = Double(punctCount) / Double(totalCount)

        return ChineseAnalysis.PunctuationInfo(
            count: punctCount,
            ratio: punctRatio
        )
    }

    /// Analyze linguistic features (classical/modern ratios)
    private func analyzeLinguisticFeatures(_ text: String) -> ChineseAnalysis.LinguisticInfo {
        ChineseAnalysis.LinguisticInfo(
            classicalRatio: text.calculateClassicalChineseMarkerRatio(),
            modernRatio: text.calculateModernChineseMarkerRatio()
        )
    }

    /// Analyze phrase structure including parallel structure and phrase lengths
    private func analyzePhraseStructure(_ contentLines: [String]) -> ChineseAnalysis.PhraseInfo {
        var parallelCount = 0
        var totalComparisons = 0

        // At least two lines are needed to compare for parallel structure
        if contentLines.count >= 2 {
            for i in 0 ..< contentLines.count - 1 {
                let similarity = compareStructuralPatterns(contentLines[i], contentLines[i + 1])
                if similarity >= 0.9 {
                    parallelCount += 1
                }
                totalComparisons += 1
            }
        }

        let parallelRatio =
            totalComparisons > 0 ? Double(parallelCount) / Double(totalComparisons) : 0.0

        // Split content lines into phrases, omitting empty subsequences
        let phrases = contentLines.joined(separator: "\n").splitIntoShortPhrases(omittingEmptySubsequences: true)
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

    // MARK: - Genre Determination

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
}
