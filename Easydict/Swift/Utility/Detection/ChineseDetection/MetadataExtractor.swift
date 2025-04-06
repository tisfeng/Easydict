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
        self.index = index
        self.cleanLine = line.cleanFormat()
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
        guard !cleanLine.isEmpty, cleanLine.count <= 20 else { return (nil, nil, nil) }

        // Step 1: Extract formatted text with markers
        extractFormattedText()

        // Step 2: Extract clean content
        let dynasty = extractDynasty()
        let title = extractTitle()
        let author = extractAuthor()

        return (dynasty, author, title)
    }

    // MARK: Private

    private let cleanLine: String
    private let index: Int

    /// Dynasty matched text with format, e.g. 〔唐代〕, [唐], ·唐·
    private var dynastyText: String?

    /// Title matched text with format, e.g. 《定风波·莫听穿林打叶声》,《定风波》, 定风波·莫听穿林打叶声
    private var titleText: String?

    /// Author matched text, cleanLine remove dynastyText and titleText
    private var authorText: String?

    // MARK: - Format Text Extraction

    /// Extract formatted text first
    private func extractFormattedText() {
        var remainingText = cleanLine

        // 1. Extract title text with brackets 《》
        if let range = findBracketRange("《", "》", in: remainingText) {
            titleText = String(remainingText[range])
            remainingText = remainingText.replacingCharacters(in: range, with: "")
        }

        // 2. Extract dynasty text
        for dynastyName in ClassicalMarker.Common.dynastyMarkers where remainingText.contains(dynastyName) {
            // Try bracket format first
            if let format = findDynastyBracketFormat(dynastyName, in: remainingText) {
                dynastyText = format
                if let range = remainingText.range(of: format) {
                    remainingText = remainingText.replacingCharacters(in: range, with: "")
                }
                break
            }

            // Try dot format
            if let format = findDynastyDotFormat(dynastyName, in: remainingText) {
                dynastyText = format
                if let range = remainingText.range(of: format) {
                    remainingText = remainingText.replacingCharacters(in: range, with: "")
                }
                break
            }
        }

        // 3. If no title in brackets, try dot format
        if titleText == nil {
            if remainingText.contains("·") {
                titleText = remainingText.components(separatedBy: "·").first.map { "\($0)·" }
                if let titleText = titleText,
                   let range = remainingText.range(of: titleText) {
                    remainingText = remainingText.replacingCharacters(in: range, with: "")
                }
            } else if index == 0 {
                titleText = remainingText
                remainingText = ""
            }
        }

        // 4. Set author text as remaining text
        if !remainingText.isEmpty {
            authorText = remainingText.trimmingCharacters(in: .whitespaces)
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

    private func extractTitle() -> String? {
        guard let titleText = titleText else { return nil }

        // Remove brackets and get first part before ·
        var title =
            titleText
                .replacingOccurrences(of: "《", with: "")
                .replacingOccurrences(of: "》", with: "")

        if title.contains("·") {
            title = title.components(separatedBy: "·").first ?? title
        }

        return validateLength(title.trimmingCharacters(in: .whitespaces), for: .title)
    }

    private func extractAuthor() -> String? {
        validateLength(authorText, for: .author)
    }

    // MARK: - Helper Methods

    private func findBracketRange(_ left: String, _ right: String, in text: String) -> Range<
        String.Index
    >? {
        guard let leftRange = text.range(of: left),
              let rightRange = text.range(of: right, range: leftRange.upperBound ..< text.endIndex)
        else { return nil }

        return leftRange.lowerBound ..< rightRange.upperBound
    }

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
        guard let content = content,
              !content.isEmpty,
              type.lengthRange.contains(content.count)
        else { return nil }
        return content
    }

    private func cleanFormat(_ text: String) -> String {
        text.replacing("——", with: "")
            .replacing(try! Regex("\\s*·\\s*"), with: "·")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - String Extensions

extension String {
    fileprivate func cleanFormat() -> String {
        replacingOccurrences(of: "——", with: "")
            .replacing(try! Regex("\\s*·\\s*"), with: "·") // #/\s*·\s*/#
            .trimmingCharacters(in: .whitespaces)
    }
}
