//
//  DictionaryRichText.swift
//  Easydict
//
//  Created by Anson on 2026/11/22.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

extension NSAttributedString.Key {
    /// Marks text drawn in the label's bold font, such as the headword inside an example.
    static let dictionaryEmphasis = NSAttributedString.Key("EZDictionaryEmphasis")
    /// Marks secondary text drawn in gray, such as grammar codes and translations.
    static let dictionarySecondary = NSAttributedString.Key("EZDictionarySecondary")
    /// Indents a paragraph by the width of two prefixes, `[firstLine, otherLines]`, so wrapped
    /// lines and translations align with the text after a number or bullet.
    static let dictionaryIndent = NSAttributedString.Key("EZDictionaryIndent")
}

// MARK: - DictionaryRichTextLabel

/// A result label whose text carries emphasis and secondary runs.
///
/// The runs are semantic attributes, resolved against the label's font and
/// appearance each time it redraws, so font size changes and dark mode still apply.
@objc(EZDictionaryRichTextLabel)
class DictionaryRichTextLabel: EZLabel {
    // MARK: Internal

    @objc var styledText: NSAttributedString? {
        didSet { text = styledText?.string }
    }

    override func updateDisplayedText() {
        super.updateDisplayedText()
        guard let styledText, let textStorage, textStorage.length == styledText.length, let font else { return }

        let boldFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
        let secondaryColor = NSColor(calibratedWhite: 0x7A / 255.0, alpha: 1)
        let fullRange = NSRange(location: 0, length: styledText.length)
        styledText.enumerateAttributes(in: fullRange) { attributes, range, _ in
            if attributes[.dictionaryEmphasis] != nil {
                textStorage.addAttribute(.font, value: boldFont, range: range)
            }
            if attributes[.dictionarySecondary] != nil {
                textStorage.addAttribute(.foregroundColor, value: secondaryColor, range: range)
            }
            if let prefixes = attributes[.dictionaryIndent] as? [String], prefixes.count == 2 {
                let base = textStorage.attribute(.paragraphStyle, at: range.location, effectiveRange: nil)
                let style = (base as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
                    ?? NSMutableParagraphStyle()
                style.firstLineHeadIndent = width(of: prefixes[0], font: font)
                style.headIndent = width(of: prefixes[1], font: font)
                textStorage.addAttribute(.paragraphStyle, value: style, range: range)
            }
        }
    }

    // MARK: Private

    private func width(of prefix: String, font: NSFont) -> CGFloat {
        guard !prefix.isEmpty else { return 0 }
        return ceil((prefix as NSString).size(withAttributes: [.font: font, .kern: 0.2]).width)
    }
}

// MARK: - DictionaryRichText

/// Builds the text of the Collins and example sentence sections of a word result.
@objc(EZDictionaryRichText)
@objcMembers
class DictionaryRichText: NSObject {
    // MARK: Internal

    /// The section title of Collins senses, such as `柯林斯 ★★★★`.
    static func collinsTitle(star: Int) -> String {
        let title = NSLocalizedString("youdao.collins.title", comment: "")
        guard star > 0 else { return title }
        return "\(title)  " + String(repeating: "★", count: min(star, 5))
    }

    /// One Collins sense: number, grammar code, register and gloss, then the
    /// English definition, then its examples with translations.
    static func collinsSense(_ sense: EZCollinsSense, number: Int) -> NSAttributedString {
        let number = "\(number). "
        let bullet = "• "
        let heading = NSMutableAttributedString(string: number)
        let labels = [sense.partOfSpeech, sense.register].compactMap { $0 }.filter { !$0.isEmpty }
        if !labels.isEmpty {
            heading.append(secondary(labels.joined(separator: " · ") + "  "))
        }
        if let meaning = sense.meaning, !meaning.isEmpty {
            heading.append(NSAttributedString(string: meaning, attributes: [.dictionaryEmphasis: true]))
        }

        let result = NSMutableAttributedString()
        appendParagraph(heading, indent: ["", number], to: result)
        appendParagraph(taggedText(sense.definition), indent: [number, number], to: result)
        for example in sense.examples {
            let line = NSMutableAttributedString(string: bullet)
            line.append(taggedText(example.text))
            appendParagraph(line, indent: [number, number + bullet], to: result)
            if let translation = example.translation, !translation.isEmpty {
                appendParagraph(secondary(translation), indent: [number + bullet, number + bullet], to: result)
            }
        }
        return result
    }

    /// One example sentence with its translation on the next line.
    static func exampleSentence(_ example: EZExampleSentence, number: Int) -> NSAttributedString {
        let number = "\(number). "
        let line = NSMutableAttributedString(string: number)
        line.append(taggedText(example.text))

        let result = NSMutableAttributedString()
        appendParagraph(line, indent: ["", number], to: result)
        if let translation = example.translation, !translation.isEmpty {
            appendParagraph(secondary(translation), indent: [number, number], to: result)
        }
        return result
    }

    /// Turns `<b>…</b>` into emphasis runs, drops other tags and decodes common entities.
    static func taggedText(_ source: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var isBold = false
        var remaining = Substring(source)
        while let open = remaining.firstIndex(of: "<") {
            appendPlain(remaining[..<open], bold: isBold, to: result)
            guard let close = remaining[open...].firstIndex(of: ">") else {
                remaining = remaining[open...]
                break
            }
            let tag = remaining[remaining.index(after: open) ..< close].lowercased()
            if tag == "b" {
                isBold = true
            } else if tag == "/b" {
                isBold = false
            }
            remaining = remaining[remaining.index(after: close)...]
        }
        appendPlain(remaining, bold: isBold, to: result)
        return result
    }

    // MARK: Private

    private static let entities = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&nbsp;": " "]

    /// Appends `paragraph` on a new line, indented by the widths of `indent`'s two prefixes.
    private static func appendParagraph(
        _ paragraph: NSAttributedString,
        indent: [String],
        to result: NSMutableAttributedString
    ) {
        if result.length > 0 {
            result.append(NSAttributedString(string: "\n"))
        }
        let start = result.length
        result.append(paragraph)
        result.addAttribute(.dictionaryIndent, value: indent, range: NSRange(location: start, length: paragraph.length))
    }

    private static func secondary(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.dictionarySecondary: true])
    }

    private static func appendPlain(_ text: Substring, bold: Bool, to result: NSMutableAttributedString) {
        guard !text.isEmpty else { return }
        var decoded = String(text)
        for (entity, character) in entities {
            decoded = decoded.replacingOccurrences(of: entity, with: character)
        }
        let attributes: [NSAttributedString.Key: Any] = bold ? [.dictionaryEmphasis: true] : [:]
        result.append(NSAttributedString(string: decoded, attributes: attributes))
    }
}
