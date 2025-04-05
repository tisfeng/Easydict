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
        let lines = splitTextIntoLines(originalText)
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
        for i in 0..<minCount {
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

    /// Split text into lines with advanced options
    /// - Parameters:
    ///   - text: Input text to split
    ///   - clean: Whether to clean the text (remove spaces, empty lines), default is true
    ///   - separators: Additional separators to split lines, default is nil
    func splitTextIntoLines(_ text: String, separators: [String] = ["\n"]) -> [String] {
        let lines = splitIntoShortPhrases(text, separators: separators)

        // If we have only one line and separators, try to split it
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
        separators: [String] = ClassicalMarker.Common.lineSeparators
    )
        -> [String]
    {
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
        -> [String]
    {
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
            (lines[0], 0),  // First line
            lines.count >= 2 ? (lines[1], 1) : nil,  // Second line
            lines.count >= 3 ? (lines[lines.count - 2], lines.count - 2) : nil,  // Second to last line
            (lines[lines.count - 1], lines.count - 1),  // Last line
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

        for i in 0..<lines.count - 1 {
            let similarity = compareStructuralPatterns(lines[i], lines[i + 1])
            if similarity >= 0.8 {  // Consider as parallel if similarity >= 80%
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
    ///     - "将进酒" -> (nil, nil, "将进酒")
    ///     - "李白〔唐代〕" -> ("唐", "李白", nil)
    ///     - "—— 五代十国 · 李煜" -> ("五代十国", "李煜", nil)
    private func extractMetadata(from line: String) -> (
        dynasty: String?, author: String?, title: String?
    ) {
        // Early return if line is empty or too long
        guard !line.isEmpty, line.count <= 20 else { return (nil, nil, nil) }

        // Clean line by removing spaces, em dash and normalize dots
        let cleanLine = cleanMetadataLine(line)

        // Extract dynasty, author, and title
        let dynasty = extractDynasty(from: cleanLine)
        let title = extractTitle(from: cleanLine)
        let author = extractAuthor(from: cleanLine)

        return (dynasty, author, title)
    }

    /// Clean metadata line by removing spaces, em dash and normalize dots
    private func cleanMetadataLine(_ line: String) -> String {
        line.replacingOccurrences(of: "——", with: "")
            .replacingOccurrences(of: " · ", with: "·")  // Normalize dots with spaces
            .replacingOccurrences(of: "：", with: "·")
            // Don't remove "代" character here
            .trimmingCharacters(in: .whitespaces)
    }

    /// Extract dynasty name from a line of text
    /// - Parameter cleanLine: Clean text line to extract dynasty from
    /// - Returns: Dynasty name if found, nil otherwise
    ///
    /// - Example:
    ///   - "李白〔唐代〕" -> "唐"
    ///   - "王维［唐］" -> "唐"
    ///   - "李白（南唐）" -> "南唐"
    ///   - "宋·苏轼" -> "宋"
    ///   - "辛弃疾·宋" -> "宋"
    ///   - "明代·李白" -> "明"
    ///   - "李白【明】" -> "明"
    ///   - "五代十国" -> "五代十国"
    private func extractDynasty(from cleanLine: String) -> String? {
        // Dynasty markers are already sorted by length (longer first)
        for dynastyName in ClassicalMarker.Common.dynastyMarkers
        where cleanLine.contains(dynastyName) {
            // Direct match for longer names (like "五代十国")
            for (left, right) in ClassicalMarker.Common.bracketPairs {
                // Check if dynasty is in brackets
                if cleanLine.contains("\(left)\(dynastyName)\(right)")
                    || cleanLine.contains("\(left)\(dynastyName)代\(right)")
                {
                    logInfo("Found dynasty \(dynastyName) in brackets")
                    return dynastyName
                }
            }

            // Check dot format or prefix
            if cleanLine.contains("·\(dynastyName)") || cleanLine.contains("\(dynastyName)·")
                || cleanLine.hasPrefix(dynastyName)
            {
                logInfo("Found dynasty \(dynastyName)")
                return dynastyName
            }
        }

        logInfo("No dynasty found")
        return nil
    }

    /// Extract title from line
    ///
    /// - Example:
    /// - Example:
    ///     - "李白〔唐代〕《将进酒》" -> "将进酒"
    ///     - "定风波·莫听穿林打叶声" -> "定风波"
    ///     - "《定风波·莫听穿林打叶声》" -> "定风波"
    ///     - "定风波" -> "定风波"
    ///     - "《定风波》" -> "定风波"
    private func extractTitle(from cleanLine: String) -> String? {
        // Extract title from 《》if present
        if cleanLine.contains("《"), cleanLine.contains("》") {
            let titlePattern = "《([^》]+)》"
            if let range = cleanLine.range(of: titlePattern, options: .regularExpression) {
                let titleMatch = cleanLine[range]
                return String(titleMatch)
                    .replacingOccurrences(of: "《", with: "")
                    .replacingOccurrences(of: "》", with: "")
                    .components(separatedBy: "·")
                    .first?
                    .trimmingCharacters(in: .whitespaces)
            }
        } else if cleanLine.contains("·") {
            // Extract title from dot separator format
            return cleanLine.components(separatedBy: "·")
                .first?
                .replacingOccurrences(of: "令", with: "")
                .trimmingCharacters(in: .whitespaces)
        } else if !cleanLine.isEmpty,
            !hasDynastyMarker(cleanLine),
            !hasAuthorMarker(cleanLine)
        {
            // If line has no dynasty or author markers, treat as title
            return cleanLine
        }
        return nil
    }

    /// Extract author from a line of text
    /// - Parameter cleanLine: Clean text line to extract author from
    /// - Returns: Author name if found, nil otherwise
    ///
    /// - Example:
    ///   - "李白【唐】" -> "李白"
    ///   - "李白〔唐代〕" -> "李白"
    ///   - "王维〔唐代〕" -> "王维"
    ///   - "李白（南唐）" -> "李白"
    ///   - "宋·苏轼" -> "苏轼"
    ///   - "宋代·李白" -> "李白"
    ///   - "唐·李白《将进酒》" -> "李白"
    ///   - "—— 李白" -> "李白"
    ///   - "李白《将进酒》" -> "李白"
    ///   - "五代十国·李煜" -> "李煜"
    private func extractAuthor(from cleanLine: String) -> String? {
        // Get clean text without brackets and dynasty markers
        var authorLine = cleanLine

        // Remove title part if exists
        if let titleRange = cleanLine.range(of: "《.*》", options: .regularExpression) {
            authorLine = authorLine.replacingCharacters(in: titleRange, with: "")
        }

        // Remove dynasty markers with brackets
        for dynasty in ClassicalMarker.Common.dynastyMarkers {
            for (left, right) in ClassicalMarker.Common.bracketPairs {
                let escapedLeft = NSRegularExpression.escapedPattern(for: left)
                let escapedRight = NSRegularExpression.escapedPattern(for: right)
                let pattern = "\(escapedLeft)\(dynasty)(代)?\(escapedRight)"

                // Create regex and try to match
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(authorLine.startIndex..., in: authorLine)
                    authorLine = regex.stringByReplacingMatches(
                        in: authorLine,
                        range: range,
                        withTemplate: ""
                    )
                }
            }

            // Remove dynasty with dot
            let dotFormats = [
                "\(dynasty)代·",
                "\(dynasty)·",
                "·\(dynasty)代",
                "·\(dynasty)",
            ]

            for format in dotFormats {
                authorLine = authorLine.replacingOccurrences(of: format, with: "")
            }
        }

        // Clean up and validate
        authorLine = authorLine.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "·", with: "")

        // Author name should be 2-4 characters
        if !authorLine.isEmpty, authorLine.count >= 2, authorLine.count <= 4 {
            logInfo("Found author: \(authorLine)")
            return authorLine
        }

        logInfo("No author found")
        return nil
    }

    /// Check if line contains dynasty marker
    private func hasDynastyMarker(_ line: String) -> Bool {
        for dynasty in ClassicalMarker.Common.dynastyMarkers where line.contains(dynasty) {
            return true
        }
        return false
    }

    /// Check if line matches author patterns
    private func hasAuthorMarker(_ line: String) -> Bool {
        // Author name usually 2-4 characters
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanLine.count >= 2 && cleanLine.count <= 4 && hasDynastyMarker(line)
    }
}
