//
//  BingDictHTMLParser.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/04.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - BingDictWordEntry

/// Parsed word entry from a Bing dictionary web page (`https://cn.bing.com/dict/search?q={word}`).
///
/// The page server-renders headword, quick Chinese senses, word forms and the
/// bilingual (网络释义) numbered senses. This parser only reads stable,
/// server-rendered fragments, so no cookies or JS execution are required.
struct BingDictWordEntry: Equatable, Sendable {
    let headword: String
    let phoneticUS: String?
    let phoneticUK: String?
    /// Quick Chinese senses line, e.g. "n. 高原；台地；平台期 v. 进入停滞期"
    let quickText: String?
    /// Quick senses split into labeled rows, e.g. "v." + "发展；开发；研制".
    let quickRows: [BingDictQuickRow]
    /// Word forms (变形), e.g. "一般现在时：develops".
    let wordForms: [BingDictWordForm]
    /// Collocations (搭配), e.g. "v.+n." + ["develop industry", ...].
    let collocations: [BingDictCollocation]
    /// Synonyms (同义词).
    let synonyms: [BingDictCollocation]
    /// Antonyms (反义词).
    let antonyms: [BingDictCollocation]
    /// Bilingual numbered senses grouped by part of speech.
    let senseGroups: [BingDictSenseGroup]

    /// Plain text used for the result pane texts and copy actions.
    var plainText: String {
        var lines: [String] = []
        if let phoneticUS, !phoneticUS.isEmpty {
            lines.append("美 [\(phoneticUS)]")
        }
        if let phoneticUK, !phoneticUK.isEmpty {
            lines.append("英 [\(phoneticUK)]")
        }
        if let quickText, !quickText.isEmpty {
            lines.append(quickText)
        }
        if !wordForms.isEmpty {
            lines.append(wordForms.map { "\($0.label)：\($0.value)" }.joined(separator: "  "))
        }
        for collocation in collocations {
            lines.append("\(collocation.label)：\(collocation.items.joined(separator: ", "))")
        }
        for synonym in synonyms {
            lines.append("同义词：\(synonym.label) \(synonym.items.joined(separator: ", "))")
        }
        for antonym in antonyms {
            lines.append("反义词：\(antonym.label) \(antonym.items.joined(separator: ", "))")
        }
        for group in senseGroups {
            for sense in group.senses
                where !sense.chinese.isEmpty || !sense.english.isEmpty {
                let head = [group.pos, sense.index, sense.grammar, sense.complement]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                let body = [sense.chinese, sense.english]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                lines.append("\(head) \(body)")
            }
        }
        return lines.joined(separator: "\n")
    }

    var bestTranslation: String? {
        // Prefer the first bilingual sense, fall back to the quick senses line.
        if let first = senseGroups.first?.senses.first, !first.chinese.isEmpty {
            return first.chinese
        }
        if let quickText, !quickText.isEmpty {
            return quickText
        }
        return nil
    }
}

// MARK: - BingDictQuickRow

/// One labeled quick-sense row, e.g. `v.` + `发展；开发；研制；发挥`.
struct BingDictQuickRow: Equatable, Sendable {
    let label: String
    let values: String
}

// MARK: - BingDictWordForm

/// One word form, e.g. `一般现在时` + `develops`.
struct BingDictWordForm: Equatable, Sendable {
    let label: String
    let value: String
}

// MARK: - BingDictCollocation

/// One collocation group, e.g. `v.+n.` + ["develop industry", "develop Economy"].
struct BingDictCollocation: Equatable, Sendable {
    let label: String
    let items: [String]
}

// MARK: - BingDictSenseGroup

/// One part-of-speech group of bilingual senses, e.g. `n.` with numbered items.
struct BingDictSenseGroup: Equatable, Sendable {
    let pos: String
    let senses: [BingDictSense]
}

// MARK: - BingDictSense

/// A numbered bilingual sense: `1. 高原 — an area of flat land that is higher...`
struct BingDictSense: Equatable, Sendable {
    let index: String
    /// Grammar labels shown before the meaning, e.g. `[i] [t]`.
    let grammar: String
    /// Complement pattern, e.g. `~ sth` / `~ (sth)`.
    let complement: String
    /// Chinese term, e.g. 高原.
    let chinese: String
    /// English definition sentence, e.g. `an area of flat land that is higher...`.
    let english: String
}

// MARK: - BingDictHTMLParser

/// Parses Bing dictionary web pages into `BingDictWordEntry` values.
///
/// Only Foundation types are used so the parser can be unit tested and reused
/// outside the app target. Regular expressions intentionally match flat,
/// server-rendered fragments (`<tr class="def_row">` rows, `<span class="bil">`,
/// `<span class="val">` and the meta description tags) that carry the full
/// bilingual sense data without requiring a real HTML DOM.
enum BingDictHTMLParser {
    // MARK: Internal

    /// Parse the dict page HTML. Returns nil when no bilingual content could be extracted.
    static func parse(_ html: String) -> BingDictWordEntry? {
        let headword = firstMatch(in: html, pattern: #"<a class="hw[^"]*"[^>]*>([^<]+)</a>"#)

        let (phoneticUS, phoneticUK) = parsePhonetics(in: html)

        var quickText: String?
        if let description = firstMatch(
            in: html,
            pattern: #"<meta name="description" content="([^"]*)""#
        )?.unescapedHTML() {
            quickText = quickSensesText(fromMetaDescription: description)
        }

        let thesaurus = parseThesaurus(in: html)
        let entry = BingDictWordEntry(
            headword: headword ?? "",
            phoneticUS: phoneticUS,
            phoneticUK: phoneticUK,
            quickText: quickText,
            quickRows: parseQuickRows(from: quickText),
            wordForms: parseWordForms(in: html),
            collocations: parseLabeledLists(in: html, labelClass: "de_title2"),
            synonyms: thesaurus.synonyms,
            antonyms: thesaurus.antonyms,
            senseGroups: parseSenseGroups(in: html)
        )

        guard !entry.senseGroups.isEmpty else { return nil }
        return entry
    }

    // MARK: Private

    private static func parsePhonetics(in html: String) -> (us: String?, uk: String?) {
        guard let description = firstMatch(
            in: html,
            pattern: #"<meta name="description" content="([^"]*)""#
        )?.unescapedHTML() else {
            return (nil, nil)
        }

        let us = firstMatch(in: description, pattern: #"美\[([^\]]+)\]"#)
            ?? firstMatch(in: description, pattern: #"(?:US|美)\[([^\]]+)\]"#)
        let uk = firstMatch(in: description, pattern: #"(?:英)\[([^\]]+)\]"#)
            ?? firstMatch(in: description, pattern: #"(?:UK|英)\[([^\]]+)\]"#)
        return (us, uk)
    }

    /// Extract quick Chinese senses from the meta description:
    /// `必应词典为您提供plateau的释义，美[..]，英[..]，n. 高原；台地 ... 网络释义： 高地；坪`.
    private static func quickSensesText(fromMetaDescription description: String) -> String? {
        // Drop the leading boilerplate up to the last phonetic bracket.
        var text = description
        if let range = text.range(of: "的释义") {
            text = String(text[range.upperBound...])
        }

        // Remove both phonetic brackets.
        for pattern in [#"美\[[^\]]*\]，?"#, #"英\[[^\]]*\]，?"#] {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(text.startIndex..., in: text)
                text = regex.stringByReplacingMatches(
                    in: text, range: range, withTemplate: ""
                )
            }
        }

        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "，, "))
        return text.isEmpty ? nil : text
    }

    /// Split the quick senses into labeled rows: `n.` / `v.` / `Web` chips.
    private static func parseQuickRows(from quickText: String?) -> [BingDictQuickRow] {
        guard let quickText, !quickText.isEmpty else { return [] }

        var text = quickText
        var web: String?
        if let range = text.range(of: "网络释义：") {
            web = String(text[range.upperBound...])
            text = String(text[..<range.lowerBound])
        }

        var rows: [BingDictQuickRow] = []
        let markerPattern = #"(?<![A-Za-z0-9])([a-zA-Z]{1,8}\.)"#
        if let regex = try? NSRegularExpression(pattern: markerPattern) {
            let ns = text as NSString
            let matches = regex.matches(
                in: text,
                range: NSRange(location: 0, length: ns.length)
            )
            for (index, match) in matches.enumerated() {
                let label = ns.substring(with: match.range(at: 1))
                let valueStart = match.range.location + match.range.length
                let valueEnd = index + 1 < matches.count
                    ? matches[index + 1].range.location
                    : ns.length
                let values = ns.substring(
                    with: NSRange(location: valueStart, length: max(0, valueEnd - valueStart))
                ).trimmingCharacters(in: CharacterSet(charactersIn: "；; "))
                if !values.isEmpty {
                    rows.append(BingDictQuickRow(label: label, values: values))
                }
            }
        }

        if rows.isEmpty {
            let values = text.trimmingCharacters(in: CharacterSet(charactersIn: "；; "))
            if !values.isEmpty {
                rows.append(BingDictQuickRow(label: "", values: values))
            }
        }

        if let web {
            let values = web.trimmingCharacters(in: CharacterSet(charactersIn: "；; "))
            if !values.isEmpty {
                rows.append(BingDictQuickRow(label: "Web", values: values))
            }
        }
        return rows
    }

    /// Word forms: `<span class="b_primtxt">一般现在时：</span><a …>develops</a>` pairs.
    private static func parseWordForms(in html: String) -> [BingDictWordForm] {
        let pattern = #"<span class="b_primtxt">([^<]+)：</span>\s*<a[^>]*>([^<]+)</a>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        var forms: [BingDictWordForm] = []
        var seen = Set<String>()
        let range = NSRange(html.startIndex..., in: html)
        for match in regex.matches(in: html, range: range) {
            guard let labelRange = Range(match.range(at: 1), in: html),
                  let valueRange = Range(match.range(at: 2), in: html) else { continue }
            let label = String(html[labelRange]).trimmingCharacters(in: .whitespaces)
            let value = String(html[valueRange]).trimmingCharacters(in: .whitespaces)
            let key = "\(label)\u{1F}\(value)"
            guard !label.isEmpty, !value.isEmpty, seen.insert(key).inserted else { continue }
            forms.append(BingDictWordForm(label: label, value: value))
        }
        return forms
    }

    /// Labeled link lists: `<div class="de_title2">v.+n.</div><div class="col_fl">…links…</div>`.
    private static func parseLabeledLists(
        in html: String,
        labelClass: String
    )
        -> [BingDictCollocation] {
        let pattern = "(?s)<div class=\"\(labelClass)[^\"]*\">([^<]+)</div>\\s*<div class=\"col_fl\">(.*?)</div>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        var lists: [BingDictCollocation] = []
        let range = NSRange(html.startIndex..., in: html)
        for match in regex.matches(in: html, range: range) {
            guard let labelRange = Range(match.range(at: 1), in: html),
                  let listRange = Range(match.range(at: 2), in: html) else { continue }
            let label = String(html[labelRange]).trimmingCharacters(in: .whitespaces)
            let plain = plainText(fromRaw: String(html[listRange]))
            let items = plain
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            guard !label.isEmpty, !items.isEmpty else { continue }
            lists.append(BingDictCollocation(label: label, items: items))
        }
        return lists
    }

    /// Synonyms/antonyms live in `#synoid` / `#antoid` containers, which may
    /// appear in either order; slice each from its content div to the next
    /// container.
    private static func parseThesaurus(
        in html: String
    )
        -> (synonyms: [BingDictCollocation], antonyms: [BingDictCollocation]) {
        func slice(after marker: String) -> String {
            guard let start = html.range(of: marker) else { return "" }
            let rest = html[start.upperBound...]
            let next = rest.range(of: "<div id=")
            let end = next?.lowerBound ?? rest.index(
                rest.startIndex,
                offsetBy: min(rest.count, 10000)
            )
            return String(rest[rest.startIndex ..< end])
        }

        return (
            parseLabeledLists(in: slice(after: "<div id=\"synoid\""), labelClass: "de_title1"),
            parseLabeledLists(in: slice(after: "<div id=\"antoid\""), labelClass: "de_title1")
        )
    }

    /// Parse the server-rendered bilingual senses (`def_row` table rows grouped
    /// by pos markers) from the page.
    private static func parseSenseGroups(in html: String) -> [BingDictSenseGroup] {
        // Position markers: <div class="pos">n.</div>
        let posPattern = #"<div class="pos">([^<]+)</div>"#
        var posMarkers: [(location: Int, pos: String)] = []
        if let posRegex = try? NSRegularExpression(pattern: posPattern) {
            let range = NSRange(html.startIndex..., in: html)
            for match in posRegex.matches(in: html, range: range) {
                guard let posRange = Range(match.range(at: 1), in: html) else { continue }
                posMarkers.append((match.range.location, String(html[posRange])))
            }
        }

        // Sense rows are flat table rows, safe for non-greedy matching.
        let rowPattern = #"(?s)<tr class="def_row">(.*?)</tr>"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern) else { return [] }

        var groups: [BingDictSenseGroup] = []
        let range = NSRange(html.startIndex..., in: html)
        for match in rowRegex.matches(in: html, range: range) {
            guard let rowRange = Range(match.range(at: 1), in: html) else { continue }
            let rowHTML = String(html[rowRange])

            let index = firstMatch(in: rowHTML, pattern: #"<div class="se_d[^"]*">([^<]*)</div>"#) ?? ""
            let grammar = grammarLabels(in: rowHTML)
            let complement = firstMatch(in: rowHTML, pattern: #"(?s)<div class="sen_com">(.*?)</div>"#)
                .map {
                    // The page separates patterns with `<span class="com_sep">`
                    // markers (`.`, `,`); stripping tags would glue the next
                    // pattern onto the punctuation.
                    let normalized = $0.replacingOccurrences(
                        of: #"<span class="com_sep[^"]*">([^<]*)</span>"#,
                        with: "$1 ",
                        options: .regularExpression
                    )
                    return plainText(fromRaw: normalized)
                } ?? ""
            let chinese = balancedSpanText(in: rowHTML, classPrefix: "bil")
            let english = balancedSpanText(in: rowHTML, classPrefix: "val")

            guard !chinese.isEmpty || !english.isEmpty else { continue }

            // The row belongs to the last pos marker before its location.
            let rowStart = match.range.location
            let pos = posMarkers
                .last { $0.location < rowStart }?
                .pos ?? ""

            let sense = BingDictSense(
                index: index,
                grammar: grammar,
                complement: complement,
                chinese: chinese,
                english: english
            )

            if let last = groups.last, last.pos == pos {
                groups.removeLast()
                groups.append(
                    BingDictSenseGroup(pos: last.pos, senses: last.senses + [sense])
                )
            } else {
                groups.append(
                    BingDictSenseGroup(pos: pos, senses: [sense])
                )
            }
        }

        return groups.filter { !$0.senses.isEmpty }
    }

    /// Grammar labels of one sense row, e.g. `[i] [t]`.
    private static func grammarLabels(in rowHTML: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: #"<span class="gra[^"]*">([^<]*)</span>"#
        ) else { return "" }
        let range = NSRange(rowHTML.startIndex..., in: rowHTML)
        return regex.matches(in: rowHTML, range: range).compactMap { match in
            Range(match.range(at: 1), in: rowHTML).map { String(rowHTML[$0]) }
        }.joined(separator: " ")
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges >= 2,
              let groupRange = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[groupRange])
    }

    /// Extract a `<span class="{classPrefix}…">…</span>` fragment as plain text.
    ///
    /// Necessary: Bing nests separator spans (`<span> </span>`) inside the
    /// value span, so a naive non-greedy match truncates the sentence; only a
    /// balanced scan finds the real closing tag.
    private static func balancedSpanText(in html: String, classPrefix: String) -> String {
        guard let opener = try? NSRegularExpression(pattern: "<span class=\"\(classPrefix)[^\"]*\">") else {
            return ""
        }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = opener.firstMatch(in: html, range: range),
              let openTagRange = Range(match.range, in: html),
              let raw = balancedSpanContent(in: html, openingTag: openTagRange)
        else { return "" }
        return plainText(fromRaw: raw)
    }

    /// Find the balanced closing tag of the span opened at `openingTag`;
    /// returns nil when the fragment is unbalanced.
    private static func balancedSpanContent(
        in html: String,
        openingTag: Range<String.Index>
    )
        -> String? {
        let contentStart = openingTag.upperBound
        var pos = contentStart
        var depth = 1

        while pos < html.endIndex {
            let openRange = html.range(of: "<span", range: pos ..< html.endIndex)
            let closeRange = html.range(of: "</span>", range: pos ..< html.endIndex)

            if let close = closeRange, openRange == nil || close.lowerBound < openRange!.lowerBound {
                depth -= 1
                if depth == 0 {
                    return String(html[contentStart ..< close.lowerBound])
                }
                pos = close.upperBound
            } else if let open = openRange,
                      let tagEnd = html.range(of: ">", range: open.lowerBound ..< html.endIndex) {
                pos = tagEnd.upperBound
                depth += 1
            } else {
                return nil
            }
        }
        return nil
    }

    private static func plainText(fromRaw raw: String) -> String {
        var plain = raw
        if let tagRegex = try? NSRegularExpression(pattern: #"(?s)<[^>]+>"#) {
            let range = NSRange(plain.startIndex..., in: plain)
            plain = tagRegex.stringByReplacingMatches(in: plain, range: range, withTemplate: "")
        }
        plain = plain.unescapedHTML()
        plain = plain.replacingOccurrences(of: "\u{00a0}", with: " ")
        return plain.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }
}

// MARK: - String Helpers

extension String {
    /// Decode the named and numeric references the dict page emits.
    ///
    /// `&amp;` is decoded last so already-escaped markup survives one pass.
    fileprivate func unescapedHTML() -> String {
        let named: [(String, String)] = [
            ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&apos;", "'"),
            ("&nbsp;", " "), ("&hellip;", "…"), ("&mdash;", "—"), ("&ndash;", "–"),
            ("&ldquo;", "“"), ("&rdquo;", "”"), ("&lsquo;", "‘"), ("&rsquo;", "’"),
            ("&middot;", "·"), ("&bull;", "•"), ("&copy;", "©"), ("&reg;", "®"),
            ("&trade;", "™"), ("&times;", "×"), ("&divide;", "÷"), ("&deg;", "°"),
            ("&plusmn;", "±"), ("&frac12;", "½"), ("&laquo;", "«"), ("&raquo;", "»"),
            ("&euro;", "€"), ("&pound;", "£"), ("&yen;", "¥"), ("&cent;", "¢"),
            ("&sect;", "§"), ("&para;", "¶"), ("&dagger;", "†"), ("&prime;", "′"),
            ("&Prime;", "″"), ("&amp;", "&"),
        ]

        var text = self
        for (entity, value) in named {
            text = text.replacingOccurrences(of: entity, with: value)
        }

        guard let regex = try? NSRegularExpression(pattern: "&#(x?)([0-9A-Fa-f]+);") else {
            return text
        }
        let ns = text as NSString
        var result = ""
        var last = 0
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            result += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            let isHex = ns.substring(with: match.range(at: 1)) == "x"
            let digits = ns.substring(with: match.range(at: 2))
            if let code = UInt32(digits, radix: isHex ? 16 : 10),
               let scalar = Unicode.Scalar(code) {
                result.append(Character(scalar))
            } else {
                result += ns.substring(with: match.range)
            }
            last = match.range.location + match.range.length
        }
        result += ns.substring(from: last)
        return result
    }
}
