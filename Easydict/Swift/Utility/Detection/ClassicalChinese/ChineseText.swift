//
//  ChineseText.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - ChineseText

class ChineseText {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(_ text: String) {
        // Initialize basic properties
        self.originalText = text
        self.content = ""

        self.lines = splitTextIntoLines(text, cleaned: true)

        // Extract metadata
        let metadata = findTitleAndAuthor(in: lines)
        self.title = metadata.title
        self.author = metadata.author
        self.titleIndex = metadata.titleIndex
        self.authorIndex = metadata.authorIndex

        // Extract content
        self.content = removeMetadataLines(
            from: lines, titleIndex: titleIndex, authorIndex: authorIndex
        ).joined(separator: "\n")

        // Extract dynasty
        self.dynasty = author.flatMap { author in
            ClassicalMarker.Common.dynastyMarkers.first { author.contains($0) }
        }
    }

    // MARK: Internal

    /// The type of classical text
    /// - `prose`: Classical prose 古文
    /// - `poetry`: Classical poetry 古诗
    /// - `lyric`: Classical lyric 古词
    /// - `modern`: Modern Chinese 现代汉语
    enum TextType {
        case prose
        case poetry
        case lyric
        case modern
    }

    let originalText: String

    /// The original text lines that cleaned empty lines.
    var lines: [String] = []

    /// The original content without title and author.
    var content: String

    var title: String?
    var titleIndex: Int? = 0
    var author: String?
    var authorIndex: Int? = 0
    var dynasty: String?
    var type: TextType = .modern

    // MARK: - Public Methods

    /// Detect the type of Chinese text and update related properties
    func detect() {
        // First check for modern features
        if originalText.hasHighModernLinguisticFeatureRatio() {
            type = .modern
            return
        }

        // Check for Ci patterns (most specific)
        if isClassicalCi() {
            type = .lyric
            return
        }

        // Check for poetry patterns
        if isClassicalPoetry() {
            type = .poetry
            return
        }

        // Check for classical prose features
        if originalText.hasHighClassicalLinguisticFeatureRatio() {
            type = .prose
            return
        }

        // Fallback to modern Chinese
        type = .modern
    }

    /// Compare two lines to determine their structural similarity.
    /// Ignores specified punctuation marks when comparing.
    /// - Parameters:
    ///   - line1: First line to compare
    ///   - line2: Second line to compare
    ///   - separators: Punctuation marks to ignore in comparison
    /// - Returns: Similarity score from 0.0 to 1.0, where:
    ///   - 1.0 indicates identical length
    ///   - 0.0 indicates completely different lengths
    func compareTwoLines(
        _ line1: String,
        _ line2: String,
        ignoring separators: [String] = ClassicalMarker.Common.lineSeparators
    )
        -> Double {
        let phrases1 = splitIntoShortPhrases(line1, separators: separators)
        let phrases2 = splitIntoShortPhrases(line2, separators: separators)

        let len1 = phrases1.reduce(0) { $0 + $1.count }
        let len2 = phrases2.reduce(0) { $0 + $1.count }

        if len1 == 0 && len2 == 0 {
            return 1.0
        } else if len1 == 0 || len2 == 0 {
            return 0.0
        }

        return Double(min(len1, len2)) / Double(max(len1, len2))
    }

    /// Compare lengths of corresponding phrases between two arrays.
    /// Used to analyze parallel structure in classical Chinese.
    /// - Parameters:
    ///   - phrases1: First array of phrases
    ///   - phrases2: Second array of phrases
    /// - Returns: Ratio of phrases with matching lengths (0.0 to 1.0)
    func comparePhraseLengths(_ phrases1: [String], _ phrases2: [String]) -> Double {
        let minCount = min(phrases1.count, phrases2.count)
        guard minCount > 0 else { return 0.0 }

        var matchCount = 0
        for i in 0 ..< minCount {
            let len1 = phrases1[i].filter { !$0.isWhitespace }.count
            let len2 = phrases2[i].filter { !$0.isWhitespace }.count
            if len1 == len2 {
                matchCount += 1
            }
        }

        return Double(matchCount) / Double(minCount)
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

        return Double(matchCount) / Double(minCount)
    }

    /// Calculate clean lengths for two lines
    func getCleanLengths(_ line1: String, _ line2: String) -> (Int, Int) {
        let cleanLine1 = line1.filter {
            !ClassicalMarker.Common.punctuationCharacters.contains(String($0))
                && !$0.isWhitespace
        }
        let cleanLine2 = line2.filter {
            !ClassicalMarker.Common.punctuationCharacters.contains(String($0))
                && !$0.isWhitespace
        }
        return (cleanLine1.count, cleanLine2.count)
    }

    /// Calculate parallel structure similarity between two lines
    func calculateParallelStructure(_ line1: String, _ line2: String) -> Double {
        // Split lines into phrases by punctuation
        let phrases1 = splitIntoShortPhrases(line1)
        let phrases2 = splitIntoShortPhrases(line2)

        guard !phrases1.isEmpty, !phrases2.isEmpty else {
            return 0.0
        }

        // Only compare phrase lengths
        return comparePhraseLengths(phrases1, phrases2)
    }

    /// Compare structural patterns between phrases.
    /// Analyzes both phrase lengths and internal structure to determine similarity.
    /// - Parameters:
    ///   - phrases1: First array of phrases
    ///   - phrases2: Second array of phrases
    /// - Returns: Similarity score between 0.0 and 1.0
    func compareStructuralPatterns(_ phrases1: [String], _ phrases2: [String]) -> Double {
        // Compare phrase lengths first
        let lengthSimilarity = comparePhraseLengths(phrases1, phrases2)

        // Calculate pattern similarity based on phrase counts
        let pattern1 = phrases1.map { $0.count }
        let pattern2 = phrases2.map { $0.count }

        let minLength = min(pattern1.count, pattern2.count)
        var matchCount = 0

        // Allow 1 character difference in length
        for i in 0 ..< minLength where abs(pattern1[i] - pattern2[i]) <= 1 {
            matchCount += 1
        }

        let structureScore = Double(matchCount) / Double(minLength)

        // Weighted combination (total weight = 1.0)
        return (lengthSimilarity * 0.6) + (structureScore * 0.4)
    }

    /// Split text into lines with advanced options
    /// - Parameters:
    ///   - text: Input text to split
    ///   - clean: Whether to clean the text (remove spaces, empty lines), default is true
    ///   - removeMetadata: Whether to remove title and author lines, default is false
    ///   - separators: Additional separators to split lines, default is nil
    func splitTextIntoLines(
        _ text: String,
        cleaned: Bool = true,
        removeMetadata: Bool = false,
        separators: [String]? = nil
    )
        -> [String] {
        // First split by newlines
        var lines = text.components(separatedBy: .newlines)

        if cleaned {
            lines = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        // Early return if empty
        guard !lines.isEmpty else { return [] }

        // Handle metadata removal if needed
        if removeMetadata {
            lines = removeMetadataLines(from: lines)
        }

        // Handle additional separators
        if let separators = separators, !separators.isEmpty {
            // If we have only one line and separators, try to split it
            if lines.count == 1, let singleLine = lines.first {
                return splitIntoShortPhrases(singleLine, separators: separators)
            }

            // Otherwise apply separators to each line
            return lines.flatMap { line -> [String] in
                let parts = splitIntoShortPhrases(line, separators: separators)
                return parts.isEmpty ? [line] : parts
            }
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
        separators: [String] = ClassicalMarker.Common.lineSeparators
    )
        -> [String] {
        var phrases = [line]
        for separator in separators {
            phrases = phrases.flatMap { $0.components(separatedBy: separator) }
        }

        return
            phrases
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
    }

    /// Check if line only contains meta punctuation marks in metadata
    func hasOnlyMetaPunctuation(_ line: String) -> Bool {
        !line.contains { char in
            let charStr = String(char)
            return charStr.rangeOfCharacter(from: .punctuationCharacters) != nil
                && !ClassicalMarker.Common.metaPunctuationCharacters.contains(charStr)
        }
    }

    /// Remove metadata (title and author) lines from the input array
    /// - Parameter lines: Array of text lines
    /// - Returns: Array with metadata lines removed
    func removeMetadataLines(from lines: [String]) -> [String] {
        let metadata = findTitleAndAuthor(in: lines)
        print("\nMetadata analysis:")
        if let title = metadata.title {
            print("- Title: \(title)")
        }
        if let author = metadata.author {
            print("- Author: \(author)")
        }

        return removeMetadataLines(
            from: lines, titleIndex: metadata.titleIndex, authorIndex: metadata.authorIndex
        )
    }

    /// Remove metadata with title index and author index
    func removeMetadataLines(
        from lines: [String],
        titleIndex: Int?,
        authorIndex: Int?
    )
        -> [String] {
        guard lines.count > 2 else { return lines }

        let startIndex = titleIndex ?? 0
        let endIndex = authorIndex ?? lines.count

        return Array(lines[startIndex + 1 ..< endIndex])
    }

    /// Find title and author in classical Chinese text
    /// - Parameter lines: Array of text lines
    /// - Returns: Tuple containing:
    ///   - title: Title text if found
    ///   - author: Author text if found
    ///   - titleIndex: Index of title line
    ///   - authorIndex: Index of author line
    func findTitleAndAuthor(in lines: [String]) -> (
        title: String?, author: String?,
        titleIndex: Int?, authorIndex: Int?
    ) {
        guard lines.count >= 2 else { return (nil, nil, nil, nil) }

        var titleIndex: Int?
        var authorIndex: Int?
        var title: String?
        var author: String?

        // First check first and last line
        let firstLine = lines[0]
        let lastLine = lines[lines.count - 1]

        // Check first line
        if isTitleOrAuthorLine(firstLine) {
            if let extractedTitle = extractCiTuneTitle(from: firstLine) {
                title = extractedTitle
                titleIndex = 0
            } else if hasTitleMarkers(firstLine) {
                title = firstLine
                titleIndex = 0
            } else if isAuthorLine(firstLine) {
                author = firstLine
                authorIndex = 0
            }
        }

        // Check last line if we haven't found both
        if titleIndex == nil || authorIndex == nil {
            if isTitleOrAuthorLine(lastLine) {
                if isAuthorLine(lastLine), authorIndex == nil {
                    author = lastLine
                    authorIndex = lines.count - 1
                } else if authorIndex == nil {
                    if let extractedTitle = extractCiTuneTitle(from: lastLine) {
                        title = extractedTitle
                        titleIndex = lines.count - 1
                    } else if hasTitleMarkers(lastLine) {
                        title = lastLine
                        titleIndex = lines.count - 1
                    }
                }
            }
        }

        // If still no title/author, check second line and second to last line
        if titleIndex == nil || authorIndex == nil, lines.count >= 3 {
            let secondLine = lines[1]
            let secondToLastLine = lines[lines.count - 2]

            // Check second line
            if isTitleOrAuthorLine(secondLine) {
                if titleIndex == nil {
                    if let extractedTitle = extractCiTuneTitle(from: secondLine) {
                        title = extractedTitle
                        titleIndex = 1
                    } else if hasTitleMarkers(secondLine) {
                        title = secondLine
                        titleIndex = 1
                    }
                }
                if authorIndex == nil, isAuthorLine(secondLine) {
                    author = secondLine
                    authorIndex = 1
                }
            }

            // Check second to last line
            if isTitleOrAuthorLine(secondToLastLine) {
                if titleIndex == nil {
                    if let extractedTitle = extractCiTuneTitle(from: secondToLastLine) {
                        title = extractedTitle
                        titleIndex = lines.count - 2
                    } else if hasTitleMarkers(secondToLastLine) {
                        title = secondToLastLine
                        titleIndex = lines.count - 2
                    }
                }
                if authorIndex == nil, isAuthorLine(secondToLastLine) {
                    author = secondToLastLine
                    authorIndex = lines.count - 2
                }
            }
        }

        return (title, author, titleIndex, authorIndex)
    }

    /// Check if a line could be a title or author line based on length and punctuation
    func isTitleOrAuthorLine(_ line: String) -> Bool {
        // Title/Author lines should be relatively short
        guard line.count <= 20 else { return false }

        // Should only contain allowed punctuation
        return hasOnlyMetaPunctuation(line)
    }

    /// Check if a line has title-specific markers
    func hasTitleMarkers(_ line: String) -> Bool {
        // Has book title marks
        if line.hasPrefix("《") && line.hasSuffix("》") {
            return true
        }

        // Has genre patterns
        if ClassicalMarker.Prose.titlePatterns.contains(where: { line.contains($0) })
            || ClassicalMarker.Poetry.titlePatterns.contains(where: { line.contains($0) })
            || ClassicalMarker.LyricPoetry.tunePatterns.contains(where: { line.contains($0.key) })
            || ClassicalMarker.Poetry.locationMarkers.contains(where: { line.contains($0) }) {
            return true
        }

        return false
    }

    /// Check if a line looks like an author attribution
    func isAuthorLine(_ line: String) -> Bool {
        if !isTitleOrAuthorLine(line) { return false }

        // Has author separator
        if line.contains("——") {
            return true
        }

        // Has dynasty marker in proper format
        if ClassicalMarker.Common.dynastyMarkers.contains(where: { dynasty in
            line.contains(dynasty) && (line.hasPrefix(dynasty) || line.contains("·\(dynasty)"))
        }) {
            return true
        }

        // Has title pattern in attribution format
        if ClassicalMarker.Prose.titlePatterns.contains(where: {
            line.hasSuffix($0) || line.contains("·\($0)")
        }) {
            return true
        }

        return false
    }
}
