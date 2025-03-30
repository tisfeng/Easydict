//
//  String+ClassicalChinese.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - Classical Chinese Detection

@objc
extension NSString {
    /// Detect if the text is classical Chinese
    public func isClassicalChinese() -> Bool {
        (self as String).isClassicalChinese()
    }
}

extension String {
    // MARK: - Public Methods

    /// Detect if the text is classical Chinese
    public func isClassicalChinese() -> Bool {
        print("\n=========== Classical Chinese Detection ===========")
        print("Text: \(self)")

        if hasHighModernLinguisticFeatureRatio() {
            print("Contains too many modern features, not classical Chinese")
            return false
        }

        if isClassicalPoetry() {
            print("✅ Detected as Classical Poetry")
            return true
        }

        if isClassicalCi() {
            print("✅ Detected as Classical Ci")
            return true
        }

        let isClassical = hasHighClassicalLinguisticFeatureRatio()
        print(isClassical ? "✅ Detected as Classical Chinese prose" : "❌ Not Classical Chinese")
        return isClassical
    }

    /// Detect if the text is Chinese classical poetry (格律诗)
    public func isClassicalPoetry() -> Bool {
        print("\n----- Classical Poetry Detection -----")
        let cleanText = trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanText.count >= 8 else { return false }

        // Split text into lines and handle both newlines and punctuation separators
        let lines = splitIntoLines(
            removeMetadata: true,
            separators: ClassicalMarker.Common.lineSeparators
        )
        guard lines.count >= 2 else { return false }

        // print char count
        print("Characters count: \(lines.joined().count)")

        // Check poetry format and structure
        let (standardLineRatio, parallelRatio) = checkPoetryFormat(lines)
        let hasStrongFormat = standardLineRatio > 0.7 || parallelRatio > 0.5
        print("Poetry format check:")
        print("- Standard line ratio: \(String(format: "%.2f", standardLineRatio))")
        print("- Parallel ratio: \(String(format: "%.2f", parallelRatio))")

        // Check markers and title format as auxiliary features
        let hasPoetryMarkers = hasClassicalPoetrySpecificMarkers()
        let hasTitleFormat = checkClassicalTitleFormat()
        print("Additional features:")
        print("- Poetry markers: \(hasPoetryMarkers ? "✅" : "❌")")
        print("- Title format: \(hasTitleFormat ? "✅" : "❌")")

        // Final decision based on multiple factors
        let isPoetry =
            hasStrongFormat
                && (
                    standardLineRatio > 0.8 // Very strong format signal
                        || (standardLineRatio > 0.6 && hasPoetryMarkers) // Good format with markers
                        || (standardLineRatio > 0.5 && hasPoetryMarkers && hasTitleFormat) // Multiple weak signals
                )

        print("Poetry detection result: \(isPoetry ? "✅" : "❌")")
        return isPoetry
    }

    /// Detect if the text is Chinese classical Ci (词)
    public func isClassicalCi() -> Bool {
        print("\n----- Classical Ci Detection -----")
        let cleanText = trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanText.count >= 12 else { return false }

        // Check punctuation ratio first
        let punctuationRatio = calculatePunctuationRatio()
        print("Punctuation ratio: \(String(format: "%.2f", punctuationRatio))")
        // If too few punctuations, less likely to be a Ci
        guard punctuationRatio >= 0.1 else {
            print("Contains too few punctuations, less likely to be a Ci")
            return false
        }

        // Split text into lines with newline
        let lines = splitIntoLines(removeMetadata: true)
        guard lines.count >= 2 else { return false }

        // Check Ci format and rhythm
        let (variableRatio, rhymingRatio) = checkCiFormatAndRhythm(lines)
        let hasCiFormat = rhymingRatio == 1.0 || variableRatio > 0.3 && rhymingRatio > 0.3

        // Check additional Ci features
        let hasTunePattern = hasCiTunePattern()
        let hasCiMarkers = hasClassicalCiSpecificMarkers()
        let hasTitleFormat = checkClassicalTitleFormat()

        print("\nCi Feature Check:")
        print("- Variable length ratio: \(String(format: "%.2f", variableRatio))")
        print("- Rhyming ratio: \(String(format: "%.2f", rhymingRatio))")
        print("- Ci format: \(hasCiFormat ? "✅" : "❌")")
        print("- Tune pattern: \(hasTunePattern ? "✅" : "❌")")
        print("- Ci markers: \(hasCiMarkers ? "✅" : "❌")")
        print("- Title format: \(hasTitleFormat ? "✅" : "❌")")

        // Final decision based on multiple factors
        let isCi =
            (hasCiFormat || hasTunePattern)
                && (
                    hasCiFormat && hasTunePattern // Strong signal: both format and tune
                        || hasCiFormat && hasCiMarkers // Format with markers
                        || hasTunePattern && hasCiMarkers // Tune with markers
                        || (variableRatio > 0.4 && hasTitleFormat && hasCiMarkers) // Multiple features
                )

        print("Ci detection result: \(isCi ? "✅" : "❌")")
        return isCi
    }

    // MARK: - Private Helper Methods

    /// Check classical title format and author attribution
    private func checkClassicalTitleFormat() -> Bool {
        let firstLine = components(separatedBy: .newlines).first ?? ""
        let lastLine = components(separatedBy: .newlines).last ?? ""

        // Title format check
        let hasGenreMarkers = hasGenreMarkers(firstLine) || hasGenreMarkers(lastLine)

        // Dynasty and author check in first/last line only
        let hasDynastyFirst = ClassicalMarker.Common.dynastyMarkers.contains {
            firstLine.contains($0)
        }
        let hasDynastyLast = ClassicalMarker.Common.dynastyMarkers.contains {
            lastLine.contains($0)
        }

        print("Title format analysis:")
        print("- Genre markers: \(hasGenreMarkers ? "✅" : "❌")")
        print("- Dynasty (first line): \(hasDynastyFirst ? "✅" : "❌")")
        print("- Dynasty (last line): \(hasDynastyLast ? "✅" : "❌")")

        return hasGenreMarkers || hasDynastyFirst || hasDynastyLast
    }

    private func hasGenreMarkers(_ line: String) -> Bool {
        let hasProseTitle = ClassicalMarker.Prose.titlePatterns.contains { line.contains($0) }
        let hasPoetryTitle = ClassicalMarker.Poetry.titlePatterns.contains { line.contains($0) }
        let hasCiTitle = ClassicalMarker.LyricPoetry.tunePatterns.contains { line.contains($0) }
        return hasProseTitle || hasPoetryTitle || hasCiTitle
    }

    /// Check poetry format and return format ratios
    private func checkPoetryFormat(_ lines: [String]) -> (
        standardLineRatio: Double, parallelRatio: Double
    ) {
        var standardCount = 0
        var parallelCount = 0

        for (index, line) in lines.enumerated() {
            // Check standard length (5/7)
            if line.count == 5 || line.count == 7 {
                standardCount += 1
            }

            // Check parallel structure
            if index < lines.count - 1 {
                let nextLine = lines[index + 1]
                if line.count == nextLine.count {
                    parallelCount += 1
                }
            }
        }

        return (
            Double(standardCount) / Double(lines.count),
            Double(parallelCount) / Double(max(1, lines.count - 1))
        )
    }

    /// Check Ci format and return format ratios, should remove metadata first
    private func checkCiFormatAndRhythm(_ lines: [String]) -> (
        variableRatio: Double, rhymingRatio: Double
    ) {
        var variableCount = 0
        var rhymingPairCount = 0
        let minLinesToCheck = 2

        guard lines.count >= minLinesToCheck else {
            return (0.0, 0.0)
        }

        // Function to get clean line length (excluding punctuation and whitespace)
        func getCleanLength(_ line: String) -> Int {
            line.filter { char in
                !ClassicalMarker.Common.punctuationCharacters.contains(String(char))
                    && !char.isWhitespace
            }.count
        }

        // Check adjacent line pairs for variable lengths and rhyming
        for i in 0 ..< (lines.count - 1) {
            let line1 = lines[i]
            let line2 = lines[i + 1]

            // Calculate clean lengths
            let len1 = getCleanLength(line1)
            let len2 = getCleanLength(line2)

            // Check for significant length variation (allows small variations)
            // Typical Ci lines often vary by 3 or more characters
            let lengthDiff = abs(len1 - len2)
            if lengthDiff >= 3 {
                variableCount += 1
            }

            // Check rhyming with more sophisticated rules
            if hasStrongRhyming(line1, line2) {
                rhymingPairCount += 1
            }
        }

        // Calculate ratios based on number of line pairs
        let linePairs = Double(lines.count - 1)
        let variableRatio = Double(variableCount) / linePairs
        let rhymingRatio = Double(rhymingPairCount) / linePairs

        return (variableRatio, rhymingRatio)
    }

    /// Check if two lines have strong rhyming pattern
    private func hasStrongRhyming(_ line1: String, _ line2: String) -> Bool {
        // Get last characters (excluding punctuation)
        let chars1 = Array(
            line1.filter { !ClassicalMarker.Common.punctuationCharacters.contains(String($0)) }
        )
        let chars2 = Array(
            line2.filter { !ClassicalMarker.Common.punctuationCharacters.contains(String($0)) }
        )

        guard let lastChar1 = chars1.last,
              let lastChar2 = chars2.last
        else {
            return false
        }

        // Check exact character match
        if lastChar1 == lastChar2 {
            return true
        }

        // Check if characters belong to same rhyme group
        for group in ClassicalMarker.rhymingGroups {
            if group.contains(lastChar1), group.contains(lastChar2) {
                return true
            }
        }

        // Consider special cases: 通转 (characters with similar sounds)
        let specialRhymePairs = [
            ("东", "风"), ("江", "扬"), ("春", "闻"), ("寒", "关"),
            ("侯", "愁"), ("萧", "朝"), ("支", "离"), ("微", "飞"),
        ]

        return specialRhymePairs.contains { pair in
            (pair.0 == String(lastChar1) && pair.1 == String(lastChar2))
                || (pair.1 == String(lastChar1) && pair.0 == String(lastChar2))
        }
    }

    /// Split text into lines with advanced options
    /// - Parameters:
    ///   - clean: Whether to clean the text (remove spaces, empty lines), default is true
    ///   - removeMetadata: Whether to remove title and author lines, default is false
    ///   - separators: Additional separators to split lines, default is nil
    private func splitIntoLines(
        clean: Bool = true,
        removeMetadata: Bool = false,
        separators: [String]? = nil
    )
        -> [String] {
        // First split by newlines
        var lines = components(separatedBy: .newlines)

        if clean {
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
                return splitSingleLine(singleLine, separators: separators)
            }

            // Otherwise apply separators to each line
            return lines.flatMap { line -> [String] in
                let parts = splitSingleLine(line, separators: separators)
                return parts.isEmpty ? [line] : parts
            }
        }

        return lines
    }

    /// Check if line only contains allowed punctuation marks in metadata
    private func hasOnlyAllowedPunctuation(_ line: String) -> Bool {
        !line.contains { char in
            let charStr = String(char)
            return charStr.rangeOfCharacter(from: .punctuationCharacters) != nil
                && !ClassicalMarker.Common.metaPunctuationCharacters.contains(charStr)
        }
    }

    /// Remove metadata (title and author) lines from the input array
    /// - Parameter lines: Array of text lines
    /// - Returns: Array with metadata lines removed
    private func removeMetadataLines(from lines: [String]) -> [String] {
        var startIndex = 0
        var endIndex = lines.count

        // Check first line for title
        if let firstLine = lines.first, firstLine.count <= 20 { // Title should not be too long
            if hasOnlyAllowedPunctuation(firstLine) {
                let isTitleLine =
                    (firstLine.contains("《") && firstLine.contains("》"))
                        // Has prose title patterns
                        || ClassicalMarker.Prose.titlePatterns.contains { firstLine.contains($0) }
                        // Has poetry title patterns
                        || ClassicalMarker.Poetry.titlePatterns.contains { firstLine.contains($0) }
                        // Has Ci tune patterns
                        || ClassicalMarker.LyricPoetry.tunePatterns.contains { firstLine.contains($0) }
                        // Has location markers in poetry titles
                        || ClassicalMarker.Poetry.locationMarkers.contains { firstLine.contains($0) }

                if isTitleLine {
                    startIndex = 1
                }
            }
        }

        // Check last line for author attribution
        if let lastLine = lines.last, lastLine.count <= 15 { // Author line should be short
            if hasOnlyAllowedPunctuation(lastLine) {
                let hasAuthorMark =
                    lastLine.contains("——") // Common author separator
                        // Dynasty markers with proper format
                        || ClassicalMarker.Common.dynastyMarkers.contains { dynasty in
                            lastLine.contains(dynasty)
                                && (lastLine.hasPrefix(dynasty) || lastLine.contains("·\(dynasty)"))
                        }
                        // Title patterns that often appear in author attribution
                        || ClassicalMarker.Prose.titlePatterns.contains {
                            lastLine.hasSuffix($0) || lastLine.contains("·\($0)")
                        }

                if hasAuthorMark {
                    endIndex -= 1
                }
            }
        }

        // Ensure we don't remove too much
        if endIndex - startIndex < 2 {
            return lines
        }

        return Array(lines[startIndex ..< endIndex])
    }

    /// Helper method to split a single line with separators
    private func splitSingleLine(_ line: String, separators: [String]) -> [String] {
        var parts = [line]
        for separator in separators {
            parts = parts.flatMap { $0.components(separatedBy: separator) }
        }
        return
            parts
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
    }

    private func hasRhymingPattern(_ line1: String, _ line2: String) -> Bool {
        guard let lastChar1 = line1.last, let lastChar2 = line2.last else {
            return false
        }

        // Check if both characters belong to the same rhyming group
        for group in ClassicalMarker.rhymingGroups {
            if group.contains(lastChar1), group.contains(lastChar2) {
                return true
            }
        }

        return lastChar1 == lastChar2
    }

    /// Find matched count for given pattern list
    private func findMatchedPatterns(in patterns: [String]) -> [String] {
        patterns.filter { contains($0) }
    }

    /// Check if text contains classical poetry markers or patterns
    private func hasClassicalPoetrySpecificMarkers() -> Bool {
        // Check common phrases
        let phraseMatches = findMatchedPatterns(in: ClassicalMarker.Poetry.commonPhrases)
        let hasCommonPhrases = phraseMatches.count >= 2

        if !phraseMatches.isEmpty {
            print("Found common phrases: \(phraseMatches.joined(separator: ", "))")
        }

        return hasCommonPhrases
    }

    private func hasClassicalCiSpecificMarkers() -> Bool {
        let matches = findMatchedPatterns(in: ClassicalMarker.LyricPoetry.commonPhrases)
        if !matches.isEmpty {
            print("Found Ci markers: \(matches.joined(separator: ", "))")
        }
        // Require at least 2 markers
        return matches.count >= 2
    }

    /// Check if text contains Ci tune patterns
    private func hasCiTunePattern() -> Bool {
        // Check for tune patterns in first and last line
        let firstLine = components(separatedBy: .newlines).first ?? ""
        let lastLine = components(separatedBy: .newlines).last ?? ""

        return ClassicalMarker.LyricPoetry.tunePatterns.contains {
            firstLine.contains($0) || lastLine.contains($0)
        }
    }

    private func calculateLinguisticFeatureRatio(for features: [String]) -> Double {
        let cleanText = removePunctuation().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return 0.0 }

        var featureCount = 0
        let totalChars = cleanText.count

        // Count features
        for char in cleanText where features.contains(String(char)) {
            featureCount += 1
        }

        // Calculate ratio
        return Double(featureCount) / Double(totalChars)
    }

    /// Calculate the ratio of punctuation marks in text
    private func calculatePunctuationRatio() -> Double {
        let text = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return 0.0 }

        var punctuationCount = 0
        for char in text
            where
            ClassicalMarker.Common.punctuationCharacters.contains(String(char)) {
            punctuationCount += 1
        }

        return Double(punctuationCount) / Double(text.count)
    }

    // MARK: - Feature Detection Methods

    private func hasHighClassicalLinguisticFeatureRatio(_ threshold: Double = 0.15) -> Bool {
        let ratio = calculateLinguisticFeatureRatio(for: ClassicalMarker.Prose.particles)
        print("Classical linguistic feature ratio: \(String(format: "%.2f", ratio))")
        return ratio > threshold
    }

    private func hasHighModernLinguisticFeatureRatio(_ threshold: Double = 0.2) -> Bool {
        let ratio = calculateLinguisticFeatureRatio(for: ClassicalMarker.Modern.particles)
        print("Modern linguistic feature ratio: \(String(format: "%.2f", ratio))")
        return ratio > threshold
    }
}

// MARK: - String Utility Extensions

extension String {
    func removePunctuation() -> String {
        components(separatedBy: .punctuationCharacters).joined()
    }

    func removePunctuation2() -> String {
        let pattern = "[\\p{P}]"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: count),
            withTemplate: ""
        )
    }
}
