//
//  NSMutableAttributedString+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/26.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSMutableAttributedString {
    /// Creates a mutable attributed string with the specified text, font, and color.
    ///
    /// - Parameters:
    ///   - text: The text content.
    ///   - font: The font to apply.
    ///   - color: The text color.
    /// - Returns: A mutable attributed string with the specified attributes.
    @objc(mm_mutableAttributedStringWithString:font:color:)
    static func mutableAttributedString(
        withText text: String,
        font: NSFont,
        color: NSColor
    )
        -> NSMutableAttributedString? {
        guard let attrString = NSAttributedString.attributedString(withText: text, font: font, color: color)
        else { return nil }
        return NSMutableAttributedString(attributedString: attrString)
    }

    /// Updates the font and color for the entire string.
    ///
    /// - Parameters:
    ///   - font: The font to apply.
    ///   - color: The text color.
    @objc(mm_updateWithFont:color:)
    func update(withFont font: NSFont?, color: NSColor?) {
        update(withFont: font, color: color, range: NSRange(location: 0, length: length))
    }

    /// Updates the font and color for a specific range.
    ///
    /// - Parameters:
    ///   - font: The font to apply.
    ///   - color: The text color.
    ///   - range: The range to apply the attributes.
    @objc(mm_updateWithFont:color:range:)
    func update(withFont font: NSFont?, color: NSColor?, range: NSRange) {
        if let font = font {
            addAttribute(.font, value: font, range: range)
        }
        if let color = color {
            addAttribute(.foregroundColor, value: color, range: range)
        }
    }

    /// Applies letter tracking only to text that can accept it.
    ///
    /// Core Text implements positive tracking on cursive scripts such as Arabic by
    /// inserting tatweel (U+0640) glyphs between joined letters. That stretches the
    /// joins and makes an initial form read like a medial one, so cursive letters and
    /// their marks keep their natural shaping and only the remaining runs receive `kern`.
    ///
    /// - Parameter kern: The tracking to apply, in points.
    @objc(mm_applyKernExcludingCursiveScripts:)
    func applyKernExcludingCursiveScripts(_ kern: CGFloat) {
        guard length > 0 else { return }
        let text = string
        var runStart: String.Index?
        var index = text.startIndex

        func flush(upTo end: String.Index) {
            guard let start = runStart else { return }
            addAttribute(.kern, value: kern, range: NSRange(start..<end, in: text))
            runStart = nil
        }

        while index < text.endIndex {
            if text[index].unicodeScalars.contains(where: isCursiveScript) {
                flush(upTo: index)
            } else if runStart == nil {
                runStart = index
            }
            index = text.index(after: index)
        }
        flush(upTo: text.endIndex)
    }

    /// Updates the font and color for text matching a regex pattern.
    ///
    /// - Parameters:
    ///   - font: The font to apply.
    ///   - color: The text color.
    ///   - pattern: The regex pattern to match.
    @objc(mm_updateWithFont:color:pattern:)
    func update(withFont font: NSFont?, color: NSColor?, pattern: String) {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: length))
            for match in matches {
                update(withFont: font, color: color, range: match.range)
            }
        } catch {
            print("Regex pattern error: \(error)")
        }
    }
}

/// Unicode blocks whose letters join contextually, where tracking inserts tatweel.
private let cursiveScriptRanges: [ClosedRange<UInt32>] = [
    0x0600...0x06FF, // Arabic
    0x0700...0x074F, // Syriac
    0x0750...0x077F, // Arabic Supplement
    0x0780...0x07BF, // Thaana
    0x07C0...0x07FF, // NKo
    0x0800...0x083F, // Samaritan
    0x0840...0x085F, // Mandaic
    0x0860...0x086F, // Syriac Supplement
    0x0870...0x089F, // Arabic Extended-B
    0x08A0...0x08FF, // Arabic Extended-A
    0xFB50...0xFDFF, // Arabic Presentation Forms-A
    0xFE70...0xFEFF, // Arabic Presentation Forms-B
    0x10EC0...0x10EFF, // Arabic Extended-C
]

/// Only letters and their marks need the cursive exemption. Digits and
/// punctuation inside the same blocks can still take tracking.
private func isCursiveScript(_ scalar: Unicode.Scalar) -> Bool {
    guard cursiveScriptRanges.contains(where: { $0.contains(scalar.value) }) else { return false }
    switch scalar.properties.generalCategory {
    case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .modifierLetter, .otherLetter,
         .nonspacingMark, .spacingMark, .enclosingMark:
        return true
    default:
        return false
    }
}
