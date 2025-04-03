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

    let originalText: String

    // MARK: - Public Methods

    /// Detect the type of Chinese text and return analysis result
    func detect() -> ChineseTextAnalysis {
        logInfo("\nStarting Chinese text detection...")

        // If already analyzed, return cached result
        if let analysis = analysis {
            return analysis
        }

        // Initialize detection process
        let lines = splitTextIntoLines(originalText, cleaned: true)
        let metadata = findTitleAndAuthor(in: lines)

        // Extract content without metadata
        let content = removeMetadataLines(
            from: lines,
            titleIndex: metadata.titleIndex,
            authorIndex: metadata.authorIndex
        ).joined(separator: "\n")

        logInfo("\nStarting analysis...")

        // Analyze content structure
        let contentInfo = analyzeStructure(content)
        logInfo("\nContent analysis:")
        logInfo("===================================================")
        logInfo("- Content: \(content)")
        logInfo("- Title: \(metadata.title ?? "")")
        logInfo("- Author: \(metadata.author ?? "")")
        logInfo("- Dynasty: \(metadata.dynasty ?? "")")
        logInfo("- Phrases count: \(contentInfo.phraseAnalysis.phrases.count)")
        logInfo("- Total characters: \(contentInfo.text.count)")
        logInfo("- Punctuation count: \(contentInfo.punctuationCount)")
        logInfo("- Punctuation ratio: \(contentInfo.punctuationRatio)")
        logInfo("- Text characters: \(contentInfo.textCharCount)")
        logInfo("- Parallel structure ratio: \(contentInfo.parallelStructureRatio)")
        logInfo("- Average phrase length: \(contentInfo.phraseAnalysis.averageLength)")
        logInfo("- Max phrase length: \(contentInfo.phraseAnalysis.maxLength)")
        logInfo("- Min phrase length: \(contentInfo.phraseAnalysis.minLength)")
        logInfo("- Uniform phrase length: \(contentInfo.phraseAnalysis.isUniformLength)")
        logInfo("- Modern Chinese marker ratio: \(contentInfo.modernChineseRatio)")
        logInfo("- Classical Chinese marker ratio: \(contentInfo.classicalChineseRatio)")
        logInfo("===================================================")

        // Determine text genre
        let detectedGenre: Genre
        if contentInfo.hasHighModernChineseMarkerRatio() {
            detectedGenre = .modern
        } else if isClassicalPoetry(contentInfo) {
            detectedGenre = .poetry
        } else if isClassicalLyrics(contentInfo, title: metadata.title) {
            detectedGenre = .lyric
        } else if isClassicalProse(contentInfo) {
            detectedGenre = .prose
        } else {
            detectedGenre = .modern
        }

        // Create and cache analysis result
        let result = ChineseTextAnalysis(
            contentInfo: contentInfo,
            originalText: originalText,
            lines: lines,
            content: content,
            title: metadata.title,
            author: metadata.author,
            dynasty: metadata.dynasty,
            titleIndex: metadata.titleIndex,
            authorIndex: metadata.authorIndex,
            genre: detectedGenre,
        )

        analysis = result
        return result
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
        logInfo("\nMetadata analysis:")
        if let title = metadata.title {
            logInfo("- Title: \(title)")
        }
        if let author = metadata.author {
            logInfo("- Author: \(author)")
        }

        return removeMetadataLines(
            from: lines, titleIndex: metadata.titleIndex, authorIndex: metadata.authorIndex
        )
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

    /// Extract metadata (dynasty, author, title) from a line
    /// - Parameter line: Input line to extract metadata from
    /// - Returns: Tuple containing extracted dynasty, author and title
    ///
    /// - Example:
    ///     - "唐·李白《将进酒》" -> ("唐", "李白", "将进酒")
    ///     - "—— 宋·苏轼《定风波·莫听穿林打叶声》" -> ("宋", "苏轼", "定风波")
    ///     - "李白 [唐]：将进酒" -> ("唐", "李白", "将进酒")
    ///     - "定风波·莫听穿林打叶声" -> (nil, nil, "定风波")
    ///     - "—— 唐 · 李白" -> ("唐", "李白", nil)
    func extractMetadata(from line: String) -> (dynasty: String?, author: String?, title: String?) {
        // Early return if line is empty or too long
        guard !line.isEmpty, line.count <= 50 else { return (nil, nil, nil) }

        // Clean line by removing spaces, em dash and normalize dots
        var cleanLine = line.replacingOccurrences(of: "——", with: "")
            .replacingOccurrences(of: " · ", with: "·") // Normalize dots with spaces
            .replacingOccurrences(of: "：", with: "·")
            .trimmingCharacters(in: .whitespaces)

        var dynasty: String?
        var author: String?
        var title: String?

        // Extract dynasty first
        for dynastyName in ClassicalMarker.Common.dynastyMarkers {
            // Common bracket formats for dynasty
            let bracketFormats = [
                ("【", "】"), ("[", "]"), ("〔", "〕"), ("(", ")"), ("（", "）"),
            ]

            // Check each format
            for (left, right) in bracketFormats {
                let bracketPattern = "\(left)\(dynastyName)\(right)"
                if cleanLine.contains(bracketPattern) {
                    dynasty = dynastyName
                    cleanLine = cleanLine.replacingOccurrences(of: bracketPattern, with: "")
                    break
                }
            }

            // Check dynasty with dot separator or at start
            if cleanLine.contains("·\(dynastyName)") {
                dynasty = dynastyName
                cleanLine = cleanLine.replacingOccurrences(of: "·\(dynastyName)", with: "")
            } else if cleanLine.hasPrefix(dynastyName) {
                dynasty = dynastyName
                cleanLine = cleanLine.replacingOccurrences(
                    of: "^\(dynastyName)·?", with: "", options: .regularExpression
                )
            }

            if dynasty != nil { break }
        }

        // Extract title from 《》if present
        if cleanLine.contains("《"), cleanLine.contains("》") {
            let titlePattern = "《([^》]+)》"
            if let range = cleanLine.range(of: titlePattern, options: .regularExpression) {
                let titleMatch = cleanLine[range]
                title = String(titleMatch)
                    .replacingOccurrences(of: "《", with: "")
                    .replacingOccurrences(of: "》", with: "")
                    .components(separatedBy: "·")
                    .first?
                    .trimmingCharacters(in: .whitespaces)
                cleanLine = cleanLine.replacingOccurrences(
                    of: titlePattern, with: "", options: .regularExpression
                )
            }
        } else if cleanLine.contains("·") {
            // Extract title from dot separator format
            title = cleanLine.components(separatedBy: "·")
                .first?
                .replacingOccurrences(of: "令", with: "")
                .trimmingCharacters(in: .whitespaces)
        }

        // Remaining clean text might be author
        cleanLine =
            cleanLine
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "·", with: "") // Remove remaining dots
        if !cleanLine.isEmpty, cleanLine.count <= 4 {
            author = cleanLine
        }

        return (dynasty, author, title)
    }

    /// Find title and author in classical Chinese text
    /// - Parameter lines: Array of text lines
    /// - Returns: Tuple containing:
    ///   - title: Title text if found
    ///   - author: Author text if found
    ///   - dynasty: Dynasty text if found
    ///   - titleIndex: Index of title line
    ///   - authorIndex: Index of author line
    func findTitleAndAuthor(in lines: [String]) -> (
        title: String?,
        author: String?,
        dynasty: String?,
        titleIndex: Int?,
        authorIndex: Int?
    ) {
        guard lines.count >= 2 else { return (nil, nil, nil, nil, nil) }

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
            let metadata = extractMetadata(from: line)

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

        return (title, author, dynasty, titleIndex, authorIndex)
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

    /// Analyze the structure of content and return detailed information
    func analyzeStructure(_ content: String) -> ContentInfo {
        // Count characters and punctuation
        let totalCount = content.count
        let punctCount = content.filter { $0.isPunctuation }.count
        let punctRatio = Double(punctCount) / Double(totalCount)

        // Analyze parallel structure
        let lines = splitTextIntoLines(content)
        var parallelCount = 0
        var totalComparisons = 0

        for i in 0 ..< lines.count - 1 {
            let similarity = compareStructuralPatterns(lines[i], lines[i + 1])
            if similarity >= 0.8 { // Consider as parallel if similarity >= 80%
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

        let phraseAnalysis = ContentInfo.PhraseAnalysis(
            averageLength: avgLength,
            maxLength: maxLength,
            minLength: minLength,
            isUniformLength: isUniform,
            phrases: phrases
        )

        let textCount = phraseLengths.reduce(0, +)

        return ContentInfo(
            phraseAnalysis: phraseAnalysis,
            text: content,
            lines: lines,
            textCharCount: textCount,
            punctuationCount: punctCount,
            punctuationRatio: punctRatio,
            parallelStructureRatio: parallelRatio,
            classicalChineseRatio: content.calculateClassicalChineseMarkerRatio(),
            modernChineseRatio: content.calculateModernChineseMarkerRatio()
        )
    }

    // MARK: Private

    private var analysis: ChineseTextAnalysis?
}
