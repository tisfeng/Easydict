//
//  MarkdownRenderer.swift
//  Easydict
//
//  Created by Lin on 2026/4/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - MarkdownRenderer

/// Lightweight Markdown-to-NSAttributedString converter tuned for AI/LLM
/// translation results. Handles ATX headings, emphasis, blockquotes, ordered
/// and unordered lists, fenced and inline code, links, and strikethrough.
/// Streaming-safe: partial input never throws and an unterminated code fence
/// is rendered through to the current end of the buffer.
struct MarkdownRenderer {
    // MARK: Internal

    /// Base text style. Block elements scale their fonts and adjust paragraph
    /// styles relative to these values so the renderer blends with the host
    /// label's font-size ratio and dark-mode colors.
    let baseFont: NSFont
    let foregroundColor: NSColor
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat

    /// Renders the given Markdown source to an attributed string, applying
    /// per-block paragraph styles and inline emphasis.
    func render(_ markdown: String) -> NSAttributedString {
        let output = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")

        var inFence = false
        var codeBuffer: [String] = []
        var blankPending = false

        for line in lines {
            if inFence {
                if isFenceMarker(line) {
                    appendCodeBlock(codeBuffer.joined(separator: "\n"), to: output)
                    codeBuffer.removeAll()
                    inFence = false
                } else {
                    codeBuffer.append(line)
                }
                continue
            }

            let trimmed = line.trimmingPrefix(while: { $0 == " " || $0 == "\t" })
            let trimmedString = String(trimmed)

            if isFenceMarker(trimmedString) {
                inFence = true
                continue
            }

            if trimmedString.isEmpty {
                if output.length > 0, !blankPending {
                    output.append(NSAttributedString(string: "\n"))
                    blankPending = true
                }
                continue
            }
            blankPending = false

            if let (level, content) = headingComponents(trimmedString) {
                appendHeading(level: level, text: content, to: output)
                continue
            }

            if trimmedString.hasPrefix("> ") || trimmedString == ">" {
                let content = trimmedString == ">"
                    ? ""
                    : String(trimmedString.dropFirst(2))
                appendBlockquote(content, to: output)
                continue
            }

            if let bullet = unorderedItem(trimmedString) {
                appendListItem(marker: "•", content: bullet, to: output)
                continue
            }

            if let (number, content) = orderedItem(trimmedString) {
                appendListItem(marker: "\(number).", content: content, to: output)
                continue
            }

            appendParagraph(trimmedString, to: output)
        }

        if inFence, !codeBuffer.isEmpty {
            appendCodeBlock(codeBuffer.joined(separator: "\n"), to: output)
        }

        return output
    }

    // MARK: Private

    private var monospaceFont: NSFont {
        NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
    }

    private var codeBackground: NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor.white.withAlphaComponent(0.08)
                : NSColor.black.withAlphaComponent(0.06)
        }
    }

    private var quoteBarColor: NSColor {
        NSColor.secondaryLabelColor.withAlphaComponent(0.6)
    }

    private var linkColor: NSColor { .linkColor }

    private func baseAttributes(
        font: NSFont? = nil,
        color: NSColor? = nil,
        paragraph: NSParagraphStyle? = nil
    )
        -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font ?? baseFont,
            .foregroundColor: color ?? foregroundColor,
            .kern: 0.2,
        ]
        attrs[.paragraphStyle] = paragraph ?? defaultParagraph()
        return attrs
    }

    private func defaultParagraph(
        firstLineIndent: CGFloat = 0,
        headIndent: CGFloat = 0,
        paragraphSpacingBefore: CGFloat = 0
    )
        -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.paragraphSpacingBefore = paragraphSpacingBefore
        style.firstLineHeadIndent = firstLineIndent
        style.headIndent = headIndent
        return style
    }

    private func appendHeading(level: Int, text: String, to output: NSMutableAttributedString) {
        let scales: [CGFloat] = [1.6, 1.4, 1.25, 1.15, 1.08, 1.04]
        let scale = scales[max(0, min(level - 1, scales.count - 1))]
        let size = baseFont.pointSize * scale
        let weight: NSFont.Weight = level <= 2 ? .bold : .semibold
        let font = NSFont.systemFont(ofSize: size, weight: weight)
        let paragraph = defaultParagraph(paragraphSpacingBefore: 4)
        let inline = renderInline(text, base: baseAttributes(font: font, paragraph: paragraph))
        output.append(inline)
        output.append(NSAttributedString(string: "\n", attributes: baseAttributes(paragraph: paragraph)))
    }

    private func appendBlockquote(_ text: String, to output: NSMutableAttributedString) {
        let indent: CGFloat = 14
        let paragraph = defaultParagraph(firstLineIndent: indent, headIndent: indent)
        let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
        var attrs = baseAttributes(font: italicFont, color: NSColor.secondaryLabelColor, paragraph: paragraph)
        attrs[.markdownBlockquote] = true
        let inline = renderInline(text, base: attrs)
        output.append(inline)
        output.append(NSAttributedString(string: "\n", attributes: attrs))
    }

    private func appendListItem(marker: String, content: String, to output: NSMutableAttributedString) {
        let markerWidth: CGFloat = marker.count > 2 ? 22 : 16
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = paragraphSpacing
        style.firstLineHeadIndent = 4
        style.headIndent = 4 + markerWidth
        style.tabStops = [NSTextTab(textAlignment: .left, location: 4 + markerWidth)]

        let prefix = "\(marker)\t"
        let attrs = baseAttributes(paragraph: style)
        output.append(NSAttributedString(string: prefix, attributes: attrs))
        output.append(renderInline(content, base: attrs))
        output.append(NSAttributedString(string: "\n", attributes: attrs))
    }

    private func appendParagraph(_ text: String, to output: NSMutableAttributedString) {
        let attrs = baseAttributes()
        output.append(renderInline(text, base: attrs))
        output.append(NSAttributedString(string: "\n", attributes: attrs))
    }

    private func appendCodeBlock(_ code: String, to output: NSMutableAttributedString) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = max(2, lineSpacing - 2)
        style.paragraphSpacing = paragraphSpacing
        style.firstLineHeadIndent = 8
        style.headIndent = 8

        var attrs = baseAttributes(font: monospaceFont, paragraph: style)
        attrs[.backgroundColor] = codeBackground
        output.append(NSAttributedString(string: code, attributes: attrs))
        output.append(NSAttributedString(string: "\n", attributes: attrs))
    }

    private func renderInline(
        _ text: String,
        base: [NSAttributedString.Key: Any]
    )
        -> NSAttributedString {
        let result = NSMutableAttributedString()
        let scalars = Array(text)
        var index = 0

        func append(_ string: String, extra: [NSAttributedString.Key: Any] = [:]) {
            var attrs = base
            for (key, value) in extra { attrs[key] = value }
            result.append(NSAttributedString(string: string, attributes: attrs))
        }

        while index < scalars.count {
            let char = scalars[index]

            if char == "`",
               let close = findClose(of: "`", in: scalars, after: index + 1) {
                let inner = String(scalars[(index + 1) ..< close])
                let codeAttrs: [NSAttributedString.Key: Any] = [
                    .font: monospaceFont,
                    .backgroundColor: codeBackground,
                ]
                append(inner, extra: codeAttrs)
                index = close + 1
                continue
            }

            if char == "*", index + 1 < scalars.count, scalars[index + 1] == "*",
               let close = findClose(of: "**", in: scalars, after: index + 2) {
                let inner = String(scalars[(index + 2) ..< close])
                let boldFont = NSFontManager.shared.convert(
                    base[.font] as? NSFont ?? baseFont,
                    toHaveTrait: .boldFontMask
                )
                result.append(renderInline(inner, base: merge(base, with: [.font: boldFont])))
                index = close + 2
                continue
            }

            if char == "*" || char == "_",
               let close = findClose(of: String(char), in: scalars, after: index + 1),
               close > index + 1 {
                let inner = String(scalars[(index + 1) ..< close])
                let italicFont = NSFontManager.shared.convert(
                    base[.font] as? NSFont ?? baseFont,
                    toHaveTrait: .italicFontMask
                )
                result.append(renderInline(inner, base: merge(base, with: [.font: italicFont])))
                index = close + 1
                continue
            }

            if char == "~", index + 1 < scalars.count, scalars[index + 1] == "~",
               let close = findClose(of: "~~", in: scalars, after: index + 2) {
                let inner = String(scalars[(index + 2) ..< close])
                result.append(renderInline(
                    inner,
                    base: merge(base, with: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
                ))
                index = close + 2
                continue
            }

            if char == "[", let link = parseLink(scalars: scalars, start: index) {
                let linkAttrs: [NSAttributedString.Key: Any] = [
                    .link: link.url,
                    .foregroundColor: linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ]
                result.append(renderInline(link.text, base: merge(base, with: linkAttrs)))
                index = link.endIndex
                continue
            }

            // Default: emit one character with base attributes
            append(String(char))
            index += 1
        }

        return result
    }

    // MARK: Block detection

    private func isFenceMarker(_ line: String) -> Bool {
        let stripped = line.trimmingCharacters(in: .whitespaces)
        return stripped.hasPrefix("```")
    }

    private func headingComponents(_ line: String) -> (level: Int, text: String)? {
        var hashCount = 0
        for char in line {
            if char == "#", hashCount < 6 { hashCount += 1 } else { break }
        }
        guard hashCount > 0 else { return nil }
        let afterHashes = line.dropFirst(hashCount)
        guard afterHashes.first == " " else { return nil }
        return (hashCount, String(afterHashes.dropFirst()).trimmingCharacters(in: .whitespaces))
    }

    private func unorderedItem(_ line: String) -> String? {
        guard line.count >= 2 else { return nil }
        let first = line.first!
        guard first == "-" || first == "*" || first == "+" else { return nil }
        guard line.dropFirst().first == " " else { return nil }
        return String(line.dropFirst(2))
    }

    private func orderedItem(_ line: String) -> (number: Int, content: String)? {
        var digitCount = 0
        for char in line {
            if char.isASCII, char.isNumber, digitCount < 9 { digitCount += 1 } else { break }
        }
        guard digitCount > 0 else { return nil }
        let afterDigits = line.dropFirst(digitCount)
        guard afterDigits.first == ".", afterDigits.dropFirst().first == " " else { return nil }
        let number = Int(line.prefix(digitCount)) ?? 1
        return (number, String(afterDigits.dropFirst(2)))
    }

    // MARK: Inline helpers

    private func findClose(of marker: String, in scalars: [Character], after start: Int) -> Int? {
        let markerChars = Array(marker)
        guard !markerChars.isEmpty else { return nil }
        var i = start
        while i + markerChars.count <= scalars.count {
            var matched = true
            for k in 0 ..< markerChars.count where scalars[i + k] != markerChars[k] {
                matched = false
                break
            }
            if matched { return i }
            i += 1
        }
        return nil
    }

    private func parseLink(scalars: [Character], start: Int)
        -> (text: String, url: URL, endIndex: Int)? {
        guard start < scalars.count, scalars[start] == "[" else { return nil }
        guard let bracketClose = findClose(of: "]", in: scalars, after: start + 1) else {
            return nil
        }
        let parenOpen = bracketClose + 1
        guard parenOpen < scalars.count, scalars[parenOpen] == "(" else { return nil }
        guard let parenClose = findClose(of: ")", in: scalars, after: parenOpen + 1) else {
            return nil
        }
        let label = String(scalars[(start + 1) ..< bracketClose])
        let urlString = String(scalars[(parenOpen + 1) ..< parenClose])
            .trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: urlString) else { return nil }
        return (label, url, parenClose + 1)
    }

    private func merge(
        _ base: [NSAttributedString.Key: Any],
        with overrides: [NSAttributedString.Key: Any]
    )
        -> [NSAttributedString.Key: Any] {
        var combined = base
        for (key, value) in overrides { combined[key] = value }
        return combined
    }
}

// MARK: - Custom attribute keys

extension NSAttributedString.Key {
    /// Marks a run that originated from a Markdown blockquote block, allowing
    /// host views to draw a side bar without re-parsing the source.
    static let markdownBlockquote = NSAttributedString.Key("EDMarkdownBlockquote")
}
