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

/// Renders AI Markdown as native attributed text, including tables and mathematical attachments.
struct MarkdownRenderer {
    // MARK: Internal

    let baseFont: NSFont
    let foregroundColor: NSColor
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat

    func render(_ markdown: String) -> NSAttributedString {
        let output = NSMutableAttributedString()
        append(MarkdownBlockParser().parse(markdown), indent: 0, quotes: [], to: output)
        // Every block owns its final paragraph separator. Retain separators inside tables.
        if output.string.hasSuffix("\n"), output.length > 0,
           (output.attribute(.paragraphStyle, at: output.length - 1, effectiveRange: nil) as? NSParagraphStyle)?
           .textBlocks.isEmpty != false {
            output.deleteCharacters(in: NSRange(location: output.length - 1, length: 1))
        }
        return output
    }

    // MARK: Private

    private var codeBackground: NSColor {
        NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor.white.withAlphaComponent(0.08) : NSColor.black.withAlphaComponent(0.06)
        }
    }

    private var inlineRenderer: MarkdownInlineRenderer { MarkdownInlineRenderer(codeBackground: codeBackground) }

    private func paragraph(indent: CGFloat) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.paragraphSpacing = max(paragraphSpacing, baseFont.pointSize * 0.25)
        style.firstLineHeadIndent = indent
        style.headIndent = indent
        style.baseWritingDirection = .natural
        style.alignment = .natural
        return style
    }

    private func attributes(
        font: NSFont? = nil,
        paragraph: NSParagraphStyle,
        quotes: [CGFloat]
    )
        -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font ?? baseFont,
            .foregroundColor: quotes.isEmpty ? foregroundColor : NSColor.secondaryLabelColor,
            .paragraphStyle: paragraph,
            .kern: 0.2,
        ]
        if !quotes.isEmpty { attrs[.markdownBlockquote] = quotes }
        return attrs
    }

    private func append(
        _ blocks: [MarkdownBlockParser.Block],
        indent: CGFloat,
        quotes: [CGFloat],
        to output: NSMutableAttributedString
    ) {
        for block in blocks {
            let style = paragraph(indent: indent)
            var attrs = attributes(paragraph: style, quotes: quotes)
            switch block {
            case let .paragraph(text):
                output.append(inlineRenderer.render(text, attributes: attrs))
            case let .heading(level, text):
                let scales: [CGFloat] = [1.6, 1.4, 1.25, 1.15, 1.08, 1.04]
                attrs[.font] = NSFont.systemFont(
                    ofSize: baseFont.pointSize * scales[level - 1],
                    weight: level <= 2 ? .bold : .semibold
                )
                style.paragraphSpacingBefore = baseFont.pointSize * 0.4
                output.append(inlineRenderer.render(text, attributes: attrs))
            case let .code(code):
                attrs[.font] = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
                attrs[.backgroundColor] = codeBackground
                style.headIndent += 6
                style.firstLineHeadIndent += 6
                output.append(NSAttributedString(string: code, attributes: attrs))
            case let .quote(children):
                append(children, indent: indent + baseFont.pointSize, quotes: quotes + [indent], to: output)
                continue
            case let .list(items):
                appendList(items, indent: indent, quotes: quotes, to: output)
                continue
            case let .table(headers, rows, alignments):
                appendTable(
                    (headers, rows, alignments),
                    indent: indent,
                    quotes: quotes,
                    to: output
                )
                continue
            case let .math(latex, source):
                style.paragraphSpacingBefore = baseFont.pointSize * 0.4
                if let formula = MarkdownMathRenderer.render(
                    latex: latex,
                    source: source,
                    font: baseFont,
                    color: attrs[.foregroundColor] as? NSColor ?? foregroundColor,
                    display: true
                ) {
                    style.alignment = .center
                    let result = NSMutableAttributedString(attributedString: formula)
                    result.addAttributes(attrs, range: NSRange(location: 0, length: result.length))
                    output.append(result)
                } else {
                    output.append(NSAttributedString(string: source, attributes: attrs))
                }
            case .rule:
                attrs[.markdownRule] = true
                output.append(NSAttributedString(string: "\u{200B}", attributes: attrs))
            }
            output.append(NSAttributedString(string: "\n", attributes: attrs))
        }
    }

    private func appendList(
        _ items: [(marker: String, blocks: [MarkdownBlockParser.Block])],
        indent: CGFloat,
        quotes: [CGFloat],
        to output: NSMutableAttributedString
    ) {
        let widest = items.map { ($0.marker as NSString).size(withAttributes: [.font: baseFont]).width }.max() ?? 0
        let contentIndent = indent + max(baseFont.pointSize * 1.4, widest + baseFont.pointSize * 0.5)
        for item in items {
            let start = output.length
            append(
                item.blocks.isEmpty ? [.paragraph("")] : item.blocks,
                indent: contentIndent,
                quotes: quotes,
                to: output
            )
            let range = (output.string as NSString).paragraphRange(for: NSRange(location: start, length: 0))
            let style = (output.attribute(.paragraphStyle, at: start, effectiveRange: nil) as? NSParagraphStyle)?
                .mutableCopy()
                as? NSMutableParagraphStyle ?? paragraph(indent: contentIndent)
            style.firstLineHeadIndent = indent
            style.tabStops = [NSTextTab(textAlignment: .left, location: contentIndent)]
            output.addAttribute(.paragraphStyle, value: style, range: range)
            let attrs = attributes(paragraph: style, quotes: quotes)
            output.insert(NSAttributedString(string: item.marker + "\t", attributes: attrs), at: start)
        }
    }

    private func appendTable(
        _ content: (headers: [String], rows: [[String]], alignments: [MarkdownBlockParser.Alignment]),
        indent: CGFloat,
        quotes: [CGFloat],
        to output: NSMutableAttributedString
    ) {
        let (headers, rows, alignments) = content
        let table = NSTextTable()
        table.numberOfColumns = headers.count
        table.layoutAlgorithm = .fixedLayoutAlgorithm
        table.collapsesBorders = true
        table.hidesEmptyCells = false
        for (row, cells) in ([headers] + rows).enumerated() {
            for column in headers.indices {
                let cell = NSTextTableBlock(
                    table: table,
                    startingRow: row,
                    rowSpan: 1,
                    startingColumn: column,
                    columnSpan: 1
                )
                cell.setValue(100 / CGFloat(headers.count), type: .percentageValueType, for: .width)
                cell.setWidth(5, type: .absoluteValueType, for: .padding)
                cell.setWidth(0.5, type: .absoluteValueType, for: .border)
                cell.setBorderColor(.separatorColor)
                if row == 0 { cell.backgroundColor = codeBackground }
                let style = paragraph(indent: indent)
                style.textBlocks = [cell]
                switch alignments[column] {
                case .left: style.alignment = .left
                case .center: style.alignment = .center
                case .right: style.alignment = .right
                }
                let font = row == 0 ? NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask) : baseFont
                let attrs = attributes(font: font, paragraph: style, quotes: quotes)
                output.append(inlineRenderer.render(column < cells.count ? cells[column] : "", attributes: attrs))
                output.append(NSAttributedString(string: "\n", attributes: attrs))
            }
        }
        // A separate paragraph prevents subsequent content from joining the last table cell.
        output.append(NSAttributedString(
            string: "\n",
            attributes: attributes(paragraph: paragraph(indent: indent), quotes: quotes)
        ))
    }
}

extension NSAttributedString.Key {
    static let markdownBlockquote = NSAttributedString.Key("EDMarkdownBlockquote")
    static let markdownRule = NSAttributedString.Key("EDMarkdownRule")
}
