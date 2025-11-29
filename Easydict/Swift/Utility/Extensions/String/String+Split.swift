//
//  String+Split.swift
//  Easydict
//
//  Created by tisfeng on 2023/10/12.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

// MARK: - String Splitting Extensions

extension String {
    // MARK: Public Methods

    /// Split camel case text by adding spaces before uppercase letters
    ///
    /// Examples:
    /// - "anchoredDraggableState" -> "anchored Draggable State"
    /// - "AnchoredDraggableState" -> "Anchored Draggable State"
    /// - "GetHTTP" -> "Get HTTP"
    /// - "GetHTTPCode" -> "Get HTTP Code"
    func splitCamelCaseText() -> String {
        var outputText = ""

        for (index, character) in enumerated() {
            let currentChar = String(character)

            // Check if current character is uppercase
            if isUppercaseChar(character) {
                if index > 0 {
                    let prevIndex = self.index(startIndex, offsetBy: index - 1)
                    let prevChar = self[prevIndex]

                    // Add space if previous character is lowercase
                    if isLowercaseChar(prevChar) {
                        outputText += " "
                    } else {
                        // Add space if next character exists and is lowercase
                        if index < count - 1 {
                            let nextIndex = self.index(startIndex, offsetBy: index + 1)
                            let nextChar = self[nextIndex]
                            if isLowercaseChar(nextChar) {
                                outputText += " "
                            }
                        }
                    }
                }
            }
            outputText += currentChar
        }

        return outputText
    }

    /// Split snake case text by replacing underscores with spaces
    ///
    /// Example:
    /// - "anchored_draggable_state" -> "anchored draggable state"
    func splitSnakeCaseText() -> String {
        replacingOccurrences(of: "_", with: " ")
    }

    // MARK: Private Methods

    /// Check if a character is uppercase letter
    private func isUppercaseChar(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { CharacterSet.uppercaseLetters.contains($0) }
    }

    /// Check if a character is lowercase letter
    private func isLowercaseChar(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { CharacterSet.lowercaseLetters.contains($0) }
    }
}

// MARK: - NSString Splitting Extensions (ObjC Compatibility)

@objc
extension NSString {
    /// Split camel case text by adding spaces before uppercase letters
    @objc(splitCamelCaseText)
    func splitCamelCaseText() -> NSString {
        (self as String).splitCamelCaseText() as NSString
    }

    /// Split snake case text by replacing underscores with spaces
    @objc(splitSnakeCaseText)
    func splitSnakeCaseText() -> NSString {
        (self as String).splitSnakeCaseText() as NSString
    }
}
