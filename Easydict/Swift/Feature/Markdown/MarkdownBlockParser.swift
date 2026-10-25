//
//  MarkdownBlockParser.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Parses block structure without flattening list or quotation nesting.
struct MarkdownBlockParser {
    // MARK: Internal

    indirect enum Block {
        case paragraph(String)
        case heading(Int, String)
        case code(String)
        case quote([Block])
        case list([(marker: String, blocks: [Block])])
        case table(headers: [String], rows: [[String]], alignments: [Alignment])
        case math(String, source: String)
        case rule
    }

    enum Alignment { case left, center, right }

    func parse(_ source: String) -> [Block] {
        parse(source.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n"), depth: 0)
    }

    // MARK: Private

    private func parse(_ lines: [String], depth: Int) -> [Block] {
        guard depth < 32 else { return [.paragraph(lines.joined(separator: "\n"))] }
        var blocks: [Block] = []
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { index += 1; continue }

            if let fence = fenceStart(trimmed) {
                index += 1
                var content: [String] = []
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    let run = candidate.prefix(while: { $0 == fence.marker })
                    if run.count >= fence.count, candidate.dropFirst(run.count).isEmpty {
                        index += 1
                        break
                    }
                    content.append(lines[index])
                    index += 1
                }
                blocks.append(.code(content.joined(separator: "\n")))
                continue
            }

            if let math = displayMath(lines, start: index) {
                blocks.append(.math(math.latex, source: math.source))
                index = math.end
                continue
            }

            if trimmed.hasPrefix(">") {
                var quoted: [String] = []
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    guard candidate.hasPrefix(">") else { break }
                    var content = candidate.dropFirst()
                    if content.first == " " { content = content.dropFirst() }
                    quoted.append(String(content))
                    index += 1
                }
                blocks.append(.quote(parse(quoted, depth: depth + 1)))
                continue
            }

            if isRule(trimmed) { blocks.append(.rule); index += 1; continue }
            if let heading = heading(trimmed) {
                blocks.append(.heading(heading.level, heading.text))
                index += 1
                continue
            }
            if listItem(line) == nil, index + 1 < lines.count, let level = setextLevel(lines[index + 1]) {
                blocks.append(.heading(level, trimmed))
                index += 2
                continue
            }
            if let item = listItem(line) {
                var items: [(marker: String, blocks: [Block])] = []
                while index < lines.count, let next = listItem(lines[index]),
                      next.indent == item.indent, next.ordered == item.ordered {
                    var content = [next.content]
                    index += 1
                    while index < lines.count {
                        let candidate = lines[index]
                        if candidate.trimmingCharacters(in: .whitespaces).isEmpty {
                            var following = index + 1
                            while following < lines.count,
                                  lines[following].trimmingCharacters(in: .whitespaces).isEmpty { following += 1 }
                            guard following < lines.count,
                                  indentation(lines[following]) >= next.contentIndent else { break }
                            content.append("")
                            index += 1
                        } else if indentation(candidate) >= next.contentIndent {
                            content.append(removingIndent(candidate, columns: next.contentIndent))
                            index += 1
                        } else { break }
                    }
                    let children = parse(content, depth: depth + 1)
                    items.append((next.marker, next.content.isEmpty ? [.paragraph("")] + children : children))
                    // A blank line can separate items of the same list.
                    var following = index
                    while following < lines.count,
                          lines[following].trimmingCharacters(in: .whitespaces).isEmpty { following += 1 }
                    if following < lines.count, let next = listItem(lines[following]),
                       next.indent == item.indent, next.ordered == item.ordered { index = following }
                }
                blocks.append(.list(items))
                continue
            }
            if index + 1 < lines.count, let alignments = tableSeparator(lines[index + 1]) {
                let headers = tableCells(line)
                if headers.count == alignments.count {
                    index += 2
                    var rows: [[String]] = []
                    while index < lines.count, lines[index].contains("|"),
                          !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
                        rows.append(tableCells(lines[index]))
                        index += 1
                    }
                    blocks.append(.table(headers: headers, rows: rows, alignments: alignments))
                    continue
                }
            }

            // Keep soft line breaks, matching the selectable plain-text result path.
            var paragraph = [line]
            index += 1
            while index < lines.count, !startsBlock(lines, at: index) {
                paragraph.append(lines[index])
                index += 1
            }
            blocks.append(.paragraph(paragraph.joined(separator: "\n")))
        }
        return blocks
    }

    private func startsBlock(_ lines: [String], at index: Int) -> Bool {
        let line = lines[index].trimmingCharacters(in: .whitespaces)
        return line.isEmpty || fenceStart(line) != nil || line.hasPrefix(">") || heading(line) != nil
            || isRule(line) || listItem(lines[index]) != nil || line.hasPrefix("$$") || line.hasPrefix("\\[")
            ||
            (index + 1 < lines
                .count && (setextLevel(lines[index + 1]) != nil || tableSeparator(lines[index + 1]) != nil))
    }

    private func fenceStart(_ line: String) -> (marker: Character, count: Int)? {
        guard let marker = line.first, marker == "`" || marker == "~" else { return nil }
        let count = line.prefix(while: { $0 == marker }).count
        guard count >= 3 else { return nil }
        if marker == "`", line.dropFirst(count).contains("`") { return nil }
        return (marker, count)
    }

    private func heading(_ line: String) -> (level: Int, text: String)? {
        let count = line.prefix(while: { $0 == "#" }).count
        guard (1 ... 6).contains(count) else { return nil }
        let rest = line.dropFirst(count)
        guard rest.isEmpty || rest.first?.isWhitespace == true else { return nil }
        var text = rest.trimmingCharacters(in: .whitespaces)
        let closing = text.reversed().prefix(while: { $0 == "#" }).count
        if closing > 0, closing < text.count, text.dropLast(closing).last?.isWhitespace == true {
            text = text.dropLast(closing).trimmingCharacters(in: .whitespaces)
        }
        return (count, text)
    }

    private func setextLevel(_ line: String) -> Int? {
        let text = line.trimmingCharacters(in: .whitespaces)
        if !text.isEmpty, text.allSatisfy({ $0 == "=" }) { return 1 }
        if !text.isEmpty, text.allSatisfy({ $0 == "-" }) { return 2 }
        return nil
    }

    private func isRule(_ line: String) -> Bool {
        let marks = line.filter { !$0.isWhitespace }
        guard marks.count >= 3, let first = marks.first, "-*_".contains(first) else { return false }
        return marks.allSatisfy { $0 == first }
    }

    private func indentation(_ line: String) -> Int {
        line.prefix(while: { $0 == " " || $0 == "\t" }).reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
    }

    private func removingIndent(_ line: String, columns: Int) -> String {
        var remaining = line[...]
        var removed = 0
        while removed < columns, let first = remaining.first, first == " " || first == "\t" {
            removed += first == "\t" ? 4 : 1
            remaining = remaining.dropFirst()
        }
        return String(remaining)
    }

    private func listItem(_ line: String)
        -> (marker: String, content: String, indent: Int, contentIndent: Int, ordered: Bool)? {
        let indent = indentation(line)
        let text = line.drop(while: { $0 == " " || $0 == "\t" })
        let digits = text.prefix(while: { $0.isASCII && $0.isNumber })
        let ordered = !digits.isEmpty
        let markerCount = ordered ? digits.count + 1 : 1
        guard let first = text.first else { return nil }
        if ordered {
            guard digits.count <= 9, let delimiter = text.dropFirst(digits.count).first,
                  delimiter == "." || delimiter == ")" else { return nil }
        } else if !"-*+".contains(first) { return nil }
        let rest = text.dropFirst(markerCount)
        guard rest.isEmpty || rest.first?.isWhitespace == true else { return nil }
        let whitespace = rest.prefix(while: { $0 == " " || $0 == "\t" })
        var content = String(rest.dropFirst(whitespace.count))
        var marker = ordered ? String(text.prefix(markerCount)) : "•"
        if !ordered, content.hasPrefix("[ ] ") || content.hasPrefix("[x] ") || content.hasPrefix("[X] ") {
            marker = content.hasPrefix("[ ]") ? "☐" : "☑"
            content = String(content.dropFirst(4))
        }
        return (marker, content, indent, indent + markerCount + max(1, whitespace.count), ordered)
    }

    private func displayMath(_ lines: [String], start: Int) -> (latex: String, source: String, end: Int)? {
        let first = lines[start].trimmingCharacters(in: .whitespaces)
        let open: String
        let close: String
        if first.hasPrefix("$$") {
            open = "$$"
            close = "$$"
        } else if first.hasPrefix("\\[") {
            open = "\\["
            close = "\\]"
        } else {
            return nil
        }
        var content = String(first.dropFirst(open.count))
        var index = start
        while true {
            if let range = content.range(of: close),
               content[range.upperBound...].trimmingCharacters(in: .whitespaces).isEmpty {
                return (String(content[..<range.lowerBound]), lines[start ... index].joined(separator: "\n"), index + 1)
            }
            index += 1
            guard index < lines.count else {
                // An unfinished display formula is one opaque block throughout streaming.
                return ("", lines[start...].joined(separator: "\n"), lines.count)
            }
            content += "\n" + lines[index]
        }
    }

    /// Split GFM table cells, preserving escaped pipes and pipes in code spans.
    private func tableCells(_ line: String) -> [String] {
        var cells: [String] = []
        var current = ""
        let chars = Array(line.trimmingCharacters(in: .whitespaces))
        var index = 0
        var codeFence = 0
        while index < chars.count {
            if chars[index] == "\\", index + 1 < chars.count {
                current.append(chars[index]); current.append(chars[index + 1]); index += 2; continue
            }
            if chars[index] == "`" {
                let count = chars[index...].prefix(while: { $0 == "`" }).count
                if codeFence == 0 { codeFence = count } else if codeFence == count { codeFence = 0 }
                current += String(repeating: "`", count: count)
                index += count
                continue
            }
            if chars[index] == "|", codeFence == 0 {
                cells.append(current)
                current = ""
            } else {
                current.append(chars[index])
            }
            index += 1
        }
        cells.append(current)
        if chars.first == "|" { cells.removeFirst() }
        if chars.last == "|", cells.last == "" { cells.removeLast() }
        return cells.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func tableSeparator(_ line: String) -> [Alignment]? {
        guard line.contains("|") else { return nil }
        let cells = tableCells(line)
        guard !cells.isEmpty else { return nil }
        var alignments: [Alignment] = []
        for cell in cells {
            let marks = cell.trimmingCharacters(in: CharacterSet(charactersIn: ":"))
            guard marks.count >= 3, marks.allSatisfy({ $0 == "-" }) else { return nil }
            alignments.append(cell.hasSuffix(":") ? (cell.hasPrefix(":") ? .center : .right) : .left)
        }
        return alignments
    }
}
