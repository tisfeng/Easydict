//
//  String+Regex.swift
//  Easydict
//
//  Created by tisfeng on 2024/1/26.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import RegexBuilder

extension String {
    func extract(withPattern pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: utf16.count)
            if let match = regex.firstMatch(in: self, options: [], range: range) {
                if let range = Range(match.range(at: 1), in: self) {
                    return String(self[range])
                }
            }
        } catch {
            logError("Invalid regex: \(error.localizedDescription)")
        }
        return nil
    }
}

extension String {
    /// Filter <think>...</think> tag content.
    /// Example:
    /// - "<think>hello</think> abc" -> " abc"
    /// - "<think>hello" -> ""
    /// - "hello<think>world</think>" -> "hello"
    /// - "hello<think>world</think> abc" -> "hello abc"
    /// - "no tags here" -> "no tags here"
    func filterThinkTagContent() -> String {
        filterTagContent("think")
    }

    func filterTagContent(_ tag: String) -> String {
        let startTag = "<\(tag)>"
        let endTag = "</\(tag)>"

        // Tag pattern
        let tagPattern = Regex {
            startTag
            ZeroOrMore {
                // Match any character (non-greedy) until </tag> is found
                NegativeLookahead(endTag)
                CharacterClass.any
            }
            // Match the closing tag if it exists
            Optionally(endTag)
        }

        // Replace all matches with an empty string
        return replacing(tagPattern, with: "")
    }
}
