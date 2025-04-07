//
//  MetadataExtractor.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/6.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import RegexBuilder

// MARK: - MetadataExtractor

class MetadataExtractor {
    // MARK: Lifecycle

    // MARK: - Initialization

    init(line: String, index: Int) {
        self.line = line
        self.index = index
    }

    // MARK: Internal

    // MARK: - Types

    enum MetadataType: String {
        case dynasty
        case author
        case title

        // MARK: Internal

        var lengthRange: ClosedRange<Int> {
            switch self {
            case .dynasty: return 1 ... 4
            case .author: return 2 ... 4
            case .title: return 2 ... 10
            }
        }
    }

    // MARK: - Public Methods

    /// Extract metadata from line
    func extract() -> (dynasty: String?, author: String?, title: String?) {
        guard !line.isEmpty, line.count <= 20 else { return (nil, nil, nil) }

        // Step 1: Extract formatted text with markers
        extractFormattedText()

        // Step 2: Extract clean content
        let dynasty = extractDynasty()
        let title = extractTitle()
        let author = extractAuthor()

        return (dynasty, author, title)
    }

    // MARK: Private

    private let line: String
    private let index: Int

    /// Dynasty matched text with format, e.g. 〔唐代〕, [唐], 唐·
    private var dynastyText: String?

    /// Title matched text with format, e.g. 《定风波·莫听穿林打叶声》,《定风波》, 定风波·莫听穿林打叶声
    private var titleText: String?

    /// Author matched text, cleanLine remove dynastyText and titleText
    private var authorText: String?

    // MARK: - Format Text Extraction

    /// Extract formatted text first
    private func extractFormattedText() {
        // Format line, remove unnecessary characters
        var remainingText = line.replacing("——", with: "")
            .replacing(#/\s*·\s*/#, with: "·") // Remove extra spaces around dot
            .trimmingCharacters(in: .whitespaces)

        // 1. Extract title text with brackets 《》: 《定风波·莫听穿林打叶声》
        if let match = remainingText.firstMatch(of: #/《.*》/#) {
            titleText = String(match.0)
            remainingText.replace(match.0, with: " ")
        }

        // 2. Extract dynasty text
        for dynastyName in ClassicalMarker.Common.dynastyMarkers where remainingText.contains(dynastyName) {
            // Try bracket format first
            if let format = findDynastyBracketFormat(dynastyName, in: remainingText) {
                dynastyText = format
                remainingText.replace(format, with: " ")
                break
            }

            // Try dot format
            if let format = findDynastyDotFormat(dynastyName, in: remainingText) {
                dynastyText = format
                remainingText.replace(format, with: " ")
                break
            }
        }

        // 3. If no title in brackets, try dot format: 定风波·莫听穿林打叶声
        if titleText == nil {
            // Equal literal regex: /.*·.*/
            let titleRegex = Regex {
                ZeroOrMore(.any)
                "·"
                ZeroOrMore(.any)
            }

            if let match = remainingText.firstMatch(of: titleRegex) {
                let title = String(match.0)
                titleText = title
                remainingText.replace(title, with: "")
            } else if index == 0 {
                titleText = remainingText
                remainingText = ""
            }
        }

        remainingText = remainingText.trimmingCharacters(in: .whitespaces)

        // 4. Set author text as remaining text
        if !remainingText.isEmpty {
            authorText = remainingText
        }
    }

    // MARK: - Content Extraction

    private func extractDynasty() -> String? {
        guard let dynastyText = dynastyText else { return nil }

        // Sort dynasty markers by length
        let sortedDynastyMarkers = ClassicalMarker.Common.dynastyMarkers.sorted { $0.count > $1.count }

        for dynasty in sortedDynastyMarkers where dynastyText.contains(dynasty) {
            return validateLength(dynasty, for: .dynasty)
        }

        return nil
    }

    /// Extract title from line, support both 《》format and dot format
    ///
    /// - Example:
    ///     - "李白〔唐代〕《将进酒》" -> "将进酒"
    ///     - "定风波·莫听穿林打叶声" -> "定风波"
    ///     - "《定风波·莫听穿林打叶声》" -> "定风波"
    ///     - "定风波" -> "定风波"
    ///     - "《定风波》" -> "定风波"
    private func extractTitle() -> String? {
        guard var title = titleText else { return nil }

        // Remove brackets 《》 from title text
        title.replace("《", with: "")
        title.replace("》", with: "")

        // Get the first part of title if contains dot
        title = title.components(separatedBy: "·").first ?? title
        title = title.trimmingCharacters(in: .whitespaces)

        return validateLength(title, for: .title)
    }

    private func extractAuthor() -> String? {
        validateLength(authorText, for: .author)
    }

    // MARK: - Helper Methods

    private func findDynastyBracketFormat(_ dynasty: String, in text: String) -> String? {
        for (left, right) in ClassicalMarker.Common.bracketPairs {
            let patterns = [
                "\(left)\(dynasty)\(right)",
                "\(left)\(dynasty)代\(right)",
                "\(left)\(dynasty)朝\(right)",
            ]

            for pattern in patterns where text.contains(pattern) {
                return pattern
            }
        }
        return nil
    }

    private func findDynastyDotFormat(_ dynasty: String, in text: String) -> String? {
        let patterns = [
            "·\(dynasty)·",
            "\(dynasty)·",
            "·\(dynasty)",
            "\(dynasty)代·",
            "·\(dynasty)代",
        ]

        return patterns.first { text.contains($0) }
    }

    private func validateLength(_ content: String?, for type: MetadataType) -> String? {
        guard let content, type.lengthRange.contains(content.count) else { return nil }
        return content
    }
}
