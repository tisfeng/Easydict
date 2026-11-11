//
//  MarkdownInlineRenderer.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

/// Uses Foundation's Markdown delimiter handling while protecting TeX from Markdown escapes and emphasis.
struct MarkdownInlineRenderer {
    // MARK: Internal

    let codeBackground: NSColor

    func containsMath(_ source: String) -> Bool {
        !protectMath(source, prefix: "").formulas.isEmpty
    }

    func containsMarkdown(_ source: String) -> Bool {
        guard source.contains(where: { "*_[<`~$\\".contains($0) }) else { return false }
        if source.contains("$") || source.contains("\\(") || source.contains("\\["), containsMath(source) {
            return true
        }
        return parseInline(source)?.runs.contains { run in
            run.link != nil || run.inlinePresentationIntent?.isEmpty == false
        } ?? false
    }

    func render(_ source: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        // Choose a prefix absent from the source so literal private-use characters remain literal.
        var prefix = "\u{E000}"
        while source.contains(prefix) { prefix += "\u{E000}" }
        let protected = protectMath(source, prefix: prefix)
        guard let parsed = parseInline(protected.text) else {
            return NSAttributedString(string: source, attributes: attributes)
        }
        let output = NSMutableAttributedString()
        for run in parsed.runs {
            var attrs = attributes
            let baseFont = attrs[.font] as? NSFont ?? .systemFont(ofSize: 14)
            let intent = run.inlinePresentationIntent ?? []
            var font = baseFont
            if intent.contains(.stronglyEmphasized) { font = NSFontManager.shared.convert(
                font,
                toHaveTrait: .boldFontMask
            ) }
            if intent.contains(.emphasized) { font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask) }
            if intent.contains(.code) {
                font = .monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
                attrs[.backgroundColor] = codeBackground
            }
            attrs[.font] = font
            if intent.contains(.strikethrough) { attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
            if let link = run.link {
                attrs[.link] = link
                attrs[.foregroundColor] = NSColor.linkColor
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }
            append(
                String(parsed[run.range].characters),
                formulas: protected.formulas,
                prefix: prefix,
                attributes: attrs,
                to: output
            )
        }
        return output
    }

    // MARK: Private

    private struct Formula {
        let token: String
        let source: String
        let latex: String?
        let display: Bool
    }

    private func parseInline(_ source: String) -> AttributedString? {
        try? AttributedString(
            markdown: source,
            options: .init(
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        )
    }

    private func append(
        _ text: String,
        formulas: [Formula],
        prefix: String,
        attributes: [NSAttributedString.Key: Any],
        to output: NSMutableAttributedString
    ) {
        var remaining = text[...]
        while let start = remaining.range(of: prefix) {
            output.append(NSAttributedString(string: String(remaining[..<start.lowerBound]), attributes: attributes))
            guard let formula = formulas.first(where: { remaining[start.lowerBound...].hasPrefix($0.token) }) else {
                output.append(NSAttributedString(string: prefix, attributes: attributes))
                remaining = remaining[start.upperBound...]
                continue
            }
            let font = attributes[.font] as? NSFont ?? .systemFont(ofSize: 14)
            let color = attributes[.foregroundColor] as? NSColor ?? .labelColor
            if let latex = formula.latex,
               let rendered = MarkdownMathRenderer.render(
                   latex: latex,
                   source: formula.source,
                   font: font,
                   color: color,
                   display: formula.display
               ) {
                let attachment = NSMutableAttributedString(attributedString: rendered)
                attachment.addAttributes(attributes, range: NSRange(location: 0, length: attachment.length))
                output.append(attachment)
            } else {
                output.append(NSAttributedString(string: formula.source, attributes: attributes))
            }
            remaining = remaining[remaining.index(start.lowerBound, offsetBy: formula.token.count)...]
        }
        output.append(NSAttributedString(string: String(remaining), attributes: attributes))
    }

    /// Link destinations are URLs, even when their path or query contains dollar signs.
    private func linkDestinationEnd(_ chars: [Character], start: Int) -> Int? {
        guard start > 0, chars[start - 1] == "]", chars[start] == "(" else { return nil }
        var depth = 1
        var index = start + 1
        while index < chars.count {
            if chars[index] == "\\" { index += 2; continue }
            if chars[index] == "(" { depth += 1 }
            if chars[index] == ")" {
                depth -= 1
                if depth == 0 { return index + 1 }
            }
            index += 1
        }
        return nil
    }

    private func autolinkEnd(_ chars: [Character], start: Int) -> Int? {
        guard chars[start] == "<" else { return nil }
        let content = chars[(start + 1)...].prefix {
            $0 != "<" && $0 != ">" && !$0.isWhitespace
        }
        guard content.endIndex < chars.count, chars[content.endIndex] == ">",
              String(content).range(
                  of: #"^[a-zA-Z][a-zA-Z0-9+.-]{1,31}:"#,
                  options: .regularExpression
              ) != nil else { return nil }
        return content.endIndex + 1
    }

    private func protectMath(_ source: String, prefix: String) -> (text: String, formulas: [Formula]) {
        let chars = Array(source)
        var text = ""
        var formulas: [Formula] = []
        var index = 0
        while index < chars.count {
            // Code spans are opaque, including multiple-backtick spans containing literal backticks.
            if chars[index] == "`" {
                let count = chars[index...].prefix(while: { $0 == "`" }).count
                let openingEnd = index + count
                var spanEnd = openingEnd
                var end = openingEnd
                while end < chars.count {
                    if chars[end] == "`" {
                        let closing = chars[end...].prefix(while: { $0 == "`" }).count
                        end += closing
                        if closing == count {
                            spanEnd = end
                            break
                        }
                    } else { end += 1 }
                }
                text += String(chars[index ..< spanEnd])
                index = spanEnd
                continue
            }
            if let end = linkDestinationEnd(chars, start: index) ?? autolinkEnd(chars, start: index) {
                text += String(chars[index ..< end])
                index = end
                continue
            }
            let open: String
            let close: String
            let display: Bool
            if chars[index] == "\\", index + 1 < chars.count, chars[index + 1] == "(" || chars[index + 1] == "[" {
                open = String(chars[index ... index + 1]); close = chars[index + 1] == "(" ? "\\)" :
                    "\\]"; display = chars[index + 1] == "["
            } else if chars[index] == "$", index + 1 < chars.count, chars[index + 1] == "$" {
                open = "$$"; close = "$$"; display = true
            } else if chars[index] == "$", index + 1 < chars.count, !chars[index + 1].isWhitespace,
                      index == 0 || !chars[index - 1].isNumber {
                open = "$"; close = "$"; display = false
            } else {
                text.append(chars[index])
                if chars[index] == "\\", index + 1 < chars.count { index += 1; text.append(chars[index]) }
                index += 1
                continue
            }
            let contentStart = index + open.count
            let numericOpener = open == "$" && chars[contentStart].isNumber
            var end = contentStart
            var closing: Int?
            while end + close.count <= chars.count {
                if String(chars[end ..< end + close.count]) == close, end > contentStart {
                    // A price-like opener must not consume a later dollar-delimited formula.
                    if numericOpener, end + 1 < chars.count, !chars[end + 1].isWhitespace,
                       chars[end - 1].isWhitespace || "([{".contains(chars[end - 1]) {
                        break
                    }
                    if close != "$" || (!chars[end - 1].isWhitespace &&
                        (end + 1 == chars.count || !chars[end + 1].isNumber)) {
                        closing = end
                        break
                    }
                    if numericOpener { break }
                }
                if chars[end] == "\\" { end += 1 }
                end += 1
            }
            if closing == nil, numericOpener {
                text.append("$")
                index += 1
                continue
            }
            let after = closing.map { $0 + close.count } ?? chars.count
            let token = prefix + String(formulas.count) + "\u{E001}"
            formulas.append(Formula(
                token: token,
                source: String(chars[index ..< after]),
                latex: closing.map { String(chars[contentStart ..< $0]) },
                display: display
            ))
            text += token
            index = after
        }
        return (text, formulas)
    }
}
