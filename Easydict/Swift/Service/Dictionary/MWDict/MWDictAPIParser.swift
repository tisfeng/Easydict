//
//  MWDictAPIParser.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/09.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - MWDictEntry

/// Parsed Merriam-Webster Collegiate entry.
///
/// Mirrors the site's structure: headword, pronunciation, inflections, then one
/// section per verb divider (`transitive verb` / `intransitive verb`) with
/// numbered senses and their examples, plus synonyms and first known use.
struct MWDictEntry: Equatable, Sendable {
    let headword: String
    let partOfSpeech: String
    let pronunciations: [String]
    let wordForms: [String]
    let sections: [MWDictSection]
    let synonyms: [String]
    let firstKnownUse: String?
    let etymology: String?
    /// Undefined run-ons, e.g. `developable adjective`.
    let runOns: [String]

    /// Plain text used for copy actions.
    var plainText: String {
        var lines: [String] = []
        if !headword.isEmpty {
            lines.append(headword)
        }
        for pronunciation in pronunciations {
            lines.append("[\(pronunciation)]")
        }
        if !wordForms.isEmpty {
            lines.append("Inflections: \(wordForms.joined(separator: "; "))")
        }
        for section in sections {
            if !section.label.isEmpty {
                lines.append(section.label)
            }
            for sense in section.senses {
                lines.append("\(sense.number) \(sense.definition)")
                for example in sense.examples {
                    lines.append("— \(example)")
                }
            }
        }
        for runOn in runOns {
            lines.append(runOn)
        }
        if !synonyms.isEmpty {
            lines.append("Synonyms: \(synonyms.joined(separator: ", "))")
        }
        return lines.joined(separator: "\n")
    }

    /// First definition, used as the translated result summary.
    var bestTranslation: String? {
        for section in sections {
            for sense in section.senses where !sense.definition.isEmpty {
                let definition = sense.definition
                    .trimmingCharacters(in: CharacterSet(charactersIn: ": "))
                // The usage note follows the arrow; the summary keeps the definition only.
                if let arrow = definition.range(of: " → ") {
                    return String(definition[..<arrow.lowerBound])
                }
                return definition
            }
        }
        return nil
    }
}

// MARK: - MWDictSection

/// One verb-divider section, e.g. `transitive verb`.
struct MWDictSection: Equatable, Sendable {
    let label: String
    let senses: [MWDictSense]
}

// MARK: - MWDictSense

/// One numbered sense with its definition and examples.
struct MWDictSense: Equatable, Sendable {
    /// Sense number as shown on the site, e.g. `1`, `1 a`, `(2)`.
    let number: String
    let definition: String
    let examples: [String]
}

// MARK: - MWDictAPIParser

/// Parses the `dictionaryapi.com` collegiate JSON into `MWDictEntry` values.
///
/// Only Foundation types are used so the parser can be unit tested without the
/// app target. The response is an array: entries are objects, while a misspelled
/// query returns an array of suggestion strings.
enum MWDictAPIParser {
    // MARK: Internal

    /// Parse the API response. Returns nil for suggestions or entries without definitions.
    static func parse(_ data: Data) -> MWDictEntry? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              let entry = json.first as? [String: Any]
        else { return nil }

        let meta = entry["meta"] as? [String: Any]
        let headwordInfo = entry["hwi"] as? [String: Any]

        var headword = stripMarkup(
            meta?["id"] as? String ?? headwordInfo?["hw"] as? String ?? ""
        ).replacingOccurrences(of: "*", with: "")
        if let homograph = headword.firstIndex(of: ":") {
            headword = String(headword[..<homograph])
        }

        var pronunciations: [String] = []
        if let prs = headwordInfo?["prs"] as? [[String: Any]] {
            for pronunciation in prs {
                let value = stripMarkup(pronunciation["mw"] as? String ?? "")
                if !value.isEmpty, !pronunciations.contains(value) {
                    pronunciations.append(value)
                }
            }
        }

        var wordForms = (entry["ins"] as? [[String: Any]] ?? [])
            .compactMap { $0["if"] as? String }
            .map { $0.replacingOccurrences(of: "*", with: "") }
            .filter { !$0.isEmpty }
        if wordForms.isEmpty {
            wordForms = (meta?["stems"] as? [String] ?? [])
                .map { $0.replacingOccurrences(of: "*", with: "") }
                .filter { !$0.isEmpty && $0.lowercased() != headword.lowercased() }
        }
        var seenForms = Set<String>()
        wordForms = wordForms.filter { seenForms.insert($0.lowercased()).inserted }

        let sections = parseSections(entry)
        guard !sections.isEmpty else { return nil }

        let firstKnownUse = stripMarkup(entry["date"] as? String ?? "")
        let etymology = parseEtymology(entry["et"])

        return MWDictEntry(
            headword: headword,
            partOfSpeech: stripMarkup(entry["fl"] as? String ?? ""),
            pronunciations: pronunciations,
            wordForms: wordForms,
            sections: sections,
            synonyms: parseSynonyms(entry["syns"]),
            firstKnownUse: firstKnownUse.isEmpty ? nil : firstKnownUse,
            etymology: etymology,
            runOns: parseRunOns(entry["uros"])
        )
    }

    /// Convert API running-text markup (`{bc}`, `{it}…{/it}`, `{sx|word|…|}`)
    /// into plain display text.
    static func stripMarkup(_ raw: String) -> String {
        let replacements: [(String, String)] = [
            (#"\{dx_def\}.*?\{/dx_def\}"#, ""),
            (#"\{dxt\|([^|}]*)[^}]*\}"#, "$1"),
            (#"\{bc\}"#, ": "),
            (#"\{ldquo\}"#, "“"),
            (#"\{rdquo\}"#, "”"),
            (#"\{sx\|([^|}]*)[^}]*\}"#, "$1"),
            (#"\{a_link\|([^}]*)\}"#, "$1"),
            (#"\{d_link\|([^|}]*)[^}]*\}"#, "$1"),
            (#"\{i_link\|([^|}]*)[^}]*\}"#, "$1"),
            (#"\{et_link\|([^|}]*)[^}]*\}"#, "$1"),
            (#"\{mat\|([^}]*)\}"#, "$1"),
            (#"\{phrase\|([^}]*)\}"#, "$1"),
            (#"\{qword\|([^}]*)\}"#, "$1"),
            (#"\{gloss\|([^}]*)\}"#, "($1)"),
            (#"\{(it|/it|wi|/wi|b|/b|sc|/sc|sup|/sup|inf|/inf|parahw|/parahw|dx|dx_def|dx_ety|p_br|/p_br)\}"#, ""),
            (#"\{[^}]*\}"#, ""),
        ]

        var text = raw
        for (pattern, template) in replacements {
            text = text.replacingOccurrences(
                of: pattern,
                with: template,
                options: .regularExpression
            )
        }
        text = text.unescapedHTMLEntities()
        return text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: " ,", with: ",")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extract example sentences from a Learner's Dictionary response.
    ///
    /// Returns an empty array for suggestions, invalid keys and responses without
    /// verbal illustrations, so the caller can treat the block as optional.
    static func extractSentences(_ data: Data) -> [String] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [Any] else {
            return []
        }

        var sentences: [String] = []

        func walk(_ node: Any) {
            // Verbal illustrations are `[ "vis", [ { "t": … } ] ]` pairs.
            if let pair = node as? [Any], pair.count == 2,
               let tag = pair[0] as? String, tag == "vis" {
                for illustration in pair[1] as? [[String: Any]] ?? [] {
                    let text = stripMarkup(illustration["t"] as? String ?? "")
                    if !text.isEmpty, !sentences.contains(text) {
                        sentences.append(text)
                    }
                }
                return
            }
            if let dictionary = node as? [String: Any] {
                for (_, value) in dictionary {
                    walk(value)
                }
                return
            }
            if let array = node as? [Any] {
                for item in array {
                    walk(item)
                }
            }
        }

        walk(json)
        return sentences
    }

    // MARK: Private

    /// Numbering state for one sense sequence.
    ///
    /// The API emits a full label on the first element (`1 a`, `2 a`, `4`) and
    /// bare letters afterwards (`b`, `c`), plus parenthesized subsenses (`(2)`).
    private struct SenseNumbering {
        var top = 1
        var letter = ""
        var last = ""
    }

    private static func parseSections(_ entry: [String: Any]) -> [MWDictSection] {
        guard let definitions = entry["def"] as? [[String: Any]] else { return [] }

        var sections: [MWDictSection] = []
        for definition in definitions {
            let label = stripMarkup(definition["vd"] as? String ?? "")
            var senses: [MWDictSense] = []

            for sequence in definition["sseq"] as? [[Any]] ?? [] {
                senses.append(contentsOf: parseSequence(sequence))
            }

            if !senses.isEmpty {
                sections.append(MWDictSection(label: label, senses: senses))
            }
        }
        return sections
    }

    /// Walk one sense sequence: top-level senses get `1`, `2`, … while binding
    /// substitutes (`bs`) get `a`, `b`, … unless the payload already carries `sn`.
    private static func parseSequence(_ sequence: [Any]) -> [MWDictSense] {
        var senses: [MWDictSense] = []
        var numbering = SenseNumbering()

        for element in sequence {
            guard let pair = element as? [Any], pair.count >= 2,
                  let tag = pair[0] as? String
            else { continue }

            switch tag {
            case "bs", "sense":
                let payload = tag == "bs"
                    ? (pair[1] as? [String: Any])?["sense"]
                    : pair[1]
                let rawNumber = stripMarkup(
                    (payload as? [String: Any])?["sn"] as? String ?? ""
                ).trimmingCharacters(in: .whitespaces)
                let label = senseLabel(rawNumber, numbering: &numbering)
                if let sense = parseSense(payload, fallbackNumber: label) {
                    senses.append(MWDictSense(
                        number: label,
                        definition: sense.definition,
                        examples: sense.examples
                    ))
                }
            case "pseq":
                for subElement in pair[1] as? [Any] ?? [] {
                    guard let subPair = subElement as? [Any], subPair.count >= 2,
                          let subTag = subPair[0] as? String
                    else { continue }
                    let payload = subTag == "bs"
                        ? (subPair[1] as? [String: Any])?["sense"]
                        : subPair[1]
                    let rawNumber = stripMarkup(
                        (payload as? [String: Any])?["sn"] as? String ?? ""
                    ).trimmingCharacters(in: .whitespaces)
                    let label = senseLabel(rawNumber, numbering: &numbering)
                    if let sense = parseSense(payload, fallbackNumber: label) {
                        senses.append(MWDictSense(
                            number: label,
                            definition: sense.definition,
                            examples: sense.examples
                        ))
                    }
                }
            default:
                continue
            }
        }
        return senses
    }

    private static func senseLabel(_ raw: String, numbering: inout SenseNumbering) -> String {
        if raw.isEmpty {
            return numbering.last.isEmpty ? "\(numbering.top)" : numbering.last
        }

        // "2 a" / "4" — a full label; remember its number.
        if let numberText = raw.range(of: #"^[0-9]+"#, options: .regularExpression).map({ String(raw[$0]) }),
           let number = Int(numberText) {
            numbering.top = number
            numbering.letter = raw
            numbering.last = raw
            return raw
        }

        // "(2)" — inherits the enclosing letter, e.g. `2 b (2)`.
        if raw.hasPrefix("(") {
            let base = numbering.letter.isEmpty ? "\(numbering.top)" : numbering.letter
            let label = "\(base) \(raw)"
            numbering.last = label
            return label
        }

        // "b" / "b (1)" — inherits the current top number, e.g. `2 b`.
        if let first = raw.first, first.isLowercase, first.isLetter {
            let label = "\(numbering.top) \(raw)"
            numbering.letter = "\(numbering.top) \(raw.prefix(1))"
            numbering.last = label
            return label
        }

        numbering.last = raw
        return raw
    }

    private static func parseSense(_ raw: Any?, fallbackNumber: String) -> MWDictSense? {
        guard let sense = raw as? [String: Any] else { return nil }

        var definitionParts: [String] = []
        var examples: [String] = []
        walkDefiningText(sense["dt"], into: &definitionParts, examples: &examples)

        // A divided sense continues the definition inline: "; specifically …".
        if let divided = sense["sdsense"] as? [String: Any] {
            let divider = stripMarkup(divided["sd"] as? String ?? "")
            var dividedParts: [String] = []
            var dividedExamples: [String] = []
            walkDefiningText(divided["dt"], into: &dividedParts, examples: &dividedExamples)
            let text = dividedParts.joined(separator: " ")
            if !text.isEmpty {
                definitionParts.append(divider.isEmpty ? "; \(text)" : "; \(divider) \(text)")
            }
            examples.append(contentsOf: dividedExamples)
        }

        let definition = definitionParts
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !definition.isEmpty || !examples.isEmpty else { return nil }

        let number = stripMarkup(sense["sn"] as? String ?? "")
            .trimmingCharacters(in: .whitespaces)
        return MWDictSense(
            number: number.isEmpty ? fallbackNumber : number,
            definition: definition,
            examples: examples
        )
    }

    private static func walkDefiningText(
        _ raw: Any?,
        into parts: inout [String],
        examples: inout [String]
    ) {
        for element in raw as? [Any] ?? [] {
            guard let pair = element as? [Any], pair.count >= 2,
                  let tag = pair[0] as? String
            else { continue }

            switch tag {
            case "text":
                let text = stripMarkup(pair[1] as? String ?? "")
                if !text.isEmpty {
                    parts.append(text)
                }
            case "vis":
                for illustration in pair[1] as? [[String: Any]] ?? [] {
                    let text = stripMarkup(illustration["t"] as? String ?? "")
                    if !text.isEmpty {
                        examples.append(text)
                    }
                }
            case "uns":
                // Usage note: the site appends it after an arrow, with its own examples.
                // Each note is itself an array of defining-text elements.
                for note in pair[1] as? [Any] ?? [] {
                    var noteParts: [String] = []
                    walkDefiningText(note, into: &noteParts, examples: &examples)
                    if !noteParts.isEmpty {
                        parts.append("→ " + noteParts.joined(separator: " "))
                    }
                }
            default:
                continue
            }
        }
    }

    private static func parseEtymology(_ raw: Any?) -> String? {
        var parts: [String] = []
        var examples: [String] = []
        walkDefiningText(raw, into: &parts, examples: &examples)
        let text = parts.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
    }

    /// Collect synonyms from `syn_list` headwords, or from the bolded words in
    /// a synonym-discussion paragraph (`pt`).
    private static func parseSynonyms(_ raw: Any?) -> [String] {
        var synonyms: [String] = []

        func append(_ word: String) {
            let cleaned = stripMarkup(word)
            guard !cleaned.isEmpty, !synonyms.contains(cleaned) else { return }
            synonyms.append(cleaned)
        }

        func walk(_ node: Any) {
            if let dictionary = node as? [String: Any] {
                if let list = dictionary["syn_list"] as? [Any] {
                    walk(list)
                }
                if let word = dictionary["wd"] as? String {
                    append(word)
                }
                if let paragraph = dictionary["pt"] as? [Any] {
                    let pattern = #"\{sc\}([^{]+)\{/sc\}"#
                    let regex = try? NSRegularExpression(pattern: pattern)
                    for case let pair as [Any] in paragraph where pair.count >= 2 {
                        guard let text = pair[1] as? String,
                              let regex
                        else { continue }
                        let range = NSRange(text.startIndex..., in: text)
                        for match in regex.matches(in: text, range: range) {
                            guard let wordRange = Range(match.range(at: 1), in: text) else { continue }
                            append(String(text[wordRange]))
                        }
                    }
                }
                return
            }
            if let array = node as? [Any] {
                for item in array {
                    walk(item)
                }
            }
        }

        if let raw {
            walk(raw)
        }
        return synonyms
    }

    /// Undefined run-ons: `developable adjective`.
    private static func parseRunOns(_ raw: Any?) -> [String] {
        guard let items = raw as? [[String: Any]] else { return [] }
        return items.compactMap { item in
            let word = stripMarkup(item["ure"] as? String ?? "").replacingOccurrences(of: "*", with: "")
            let part = stripMarkup(item["fl"] as? String ?? "")
            guard !word.isEmpty else { return nil }
            return part.isEmpty ? word : "\(word) \(part)"
        }
    }

    private static func letterLetter(_ index: Int) -> String {
        guard let scalar = UnicodeScalar(96 + index), index >= 1, index <= 26 else {
            return "\(index)"
        }
        return String(Character(scalar))
    }
}

// MARK: - String + HTMLEntities

extension String {
    fileprivate func unescapedHTMLEntities() -> String {
        replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
