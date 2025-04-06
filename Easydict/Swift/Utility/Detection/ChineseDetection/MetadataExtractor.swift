//
//  MetadataExtractor.swift
//  Easydict
//
//  Created by tisfeng on 2025/4/6.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - MetadataExtractor

struct MetadataExtractor {
    // MARK: Lifecycle

    init(_ line: String) {
        self.cleanLine = line.cleanFormat()
    }

    // MARK: Internal

    // MARK: - MetadataType

    enum MetadataType {
        case dynasty
        case author
        case title

        // MARK: Internal

        var maxLength: Int {
            switch self {
            case .dynasty: return 4
            case .author: return 4
            case .title: return 10
            }
        }

        var minLength: Int {
            switch self {
            case .dynasty: return 1
            case .author: return 2
            case .title: return 2
            }
        }
    }

    let cleanLine: String

    var title: String?
    var author: String?
    var dynasty: String?

    /// Find content between brackets
    func findInBrackets(_ content: String) -> String? {
        for (left, right) in ClassicalMarker.Common.bracketPairs {
            let pattern = "\(left)([^\(right)]+)\(right)"
            if let match = cleanLine.firstMatch(pattern: pattern) {
                return match
            }
        }
        return nil
    }

    /// Find content around dot
    func findAroundDot(_ content: String) -> String? {
        let patterns = [
            "^(\(content))·",
            "·(\(content))$",
            "^(\(content))代·",
            "·(\(content))代$",
        ]

        for pattern in patterns {
            if let match = cleanLine.firstMatch(pattern: pattern) {
                return match
            }
        }
        return nil
    }

    /// Validate content length
    func validateLength(_ content: String?, for type: MetadataType) -> String? {
        guard let content = content,
              content.count >= type.minLength,
              content.count <= type.maxLength
        else { return nil }
        return content
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
    func extractDynasty() -> String? {
        for dynastyName in ClassicalMarker.Common.dynastyMarkers
            where cleanLine.contains(dynastyName) {
            // Check bracket format
            for (left, right) in ClassicalMarker.Common.bracketPairs {
                if cleanLine.contains("\(left)\(dynastyName)\(right)")
                    || cleanLine.contains("\(left)\(dynastyName)代\(right)") {
                    logInfo("Found dynasty \(dynastyName) in brackets")
                    return dynastyName
                }
            }

            // Check dot format or prefix
            if cleanLine.contains("·\(dynastyName)") || cleanLine.contains("\(dynastyName)·")
                || cleanLine.hasPrefix(dynastyName) {
                logInfo("Found dynasty \(dynastyName)")
                return dynastyName
            }
        }

        logInfo("No dynasty found")
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
    func extractTitle() -> String? {
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
        } else if !containsDynasty(), !containsAuthor() {
            // If line has no dynasty or author markers, treat as title
            return cleanLine
        }
        return nil
    }

    /// Extract author by removing dynasty and title markers
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
    func extractAuthor() -> String? {
        var line = cleanLine

        // Remove title part
        if let titleRange = line.range(of: "《.*》", options: .regularExpression) {
            line = line.replacingCharacters(in: titleRange, with: "")
        }

        // Remove dynasty markers
        for dynasty in ClassicalMarker.Common.dynastyMarkers {
            for (left, right) in ClassicalMarker.Common.bracketPairs {
                let escapedLeft = NSRegularExpression.escapedPattern(for: left)
                let escapedRight = NSRegularExpression.escapedPattern(for: right)
                let pattern = "\(escapedLeft)\(dynasty)(代)?\(escapedRight)"

                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(line.startIndex..., in: line)
                    line = regex.stringByReplacingMatches(
                        in: line, range: range, withTemplate: ""
                    )
                }
            }

            // Remove dynasty with dot format
            let dotFormats = [
                "\(dynasty)代·", "\(dynasty)·",
                "·\(dynasty)代", "·\(dynasty)",
            ]

            for format in dotFormats {
                line = line.replacingOccurrences(of: format, with: "")
            }
        }

        // Clean up and validate
        line = line.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "·", with: "")

        // Author name should be 2-4 characters
        if !line.isEmpty, line.count >= 2, line.count <= 4 {
            logInfo("Found author: \(line)")
            return line
        }

        logInfo("No author found")
        return nil
    }

    // MARK: Private

    private func containsDynasty() -> Bool {
        for dynasty in ClassicalMarker.Common.dynastyMarkers where cleanLine.contains(dynasty) {
            return true
        }
        return false
    }

    private func containsAuthor() -> Bool {
        let line = cleanLine.trimmingCharacters(in: .whitespaces)
        return line.count >= 2 && line.count <= 4 && containsDynasty()
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

extension String {
    fileprivate func cleanFormat() -> String {
        replacingOccurrences(of: "——", with: "")
            .replacingOccurrences(of: " · ", with: "·")
            .replacingOccurrences(of: "：", with: "·")
            .trimmingCharacters(in: .whitespaces)
    }

    fileprivate func firstMatch(pattern: String) -> String? {
        guard let range = range(of: pattern, options: .regularExpression),
              let match = self[range].components(
                  separatedBy: CharacterSet(charactersIn: "《》[]()（）【】〔〕")
              ).first
        else { return nil }
        return String(match)
    }
}
