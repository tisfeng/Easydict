//
//  AppleDictionaryGlossClient.swift
//  Easydict
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - AppleDictionaryGlossClient

/// Short English-Chinese glosses from the Oxford English-Chinese dictionary that ships with macOS.
///
/// The dictionary is free but not installed by default: it is enabled in
/// Dictionary.app → Settings. When it is missing, every lookup returns `nil`.
@MainActor
final class AppleDictionaryGlossClient {
    // MARK: Internal

    /// Whether the dictionary is installed.
    var isAvailable: Bool {
        dictionary != nil
    }

    /// The gloss for exactly `word`, if the dictionary has an entry for it.
    func definition(for word: String) -> WordDefinition? {
        if let cached = cache[word] {
            return cached
        }
        guard let dictionary else { return nil }
        let entry = dictionary.entries(forSearchTerm: word)
            .first { $0.headword.caseInsensitiveCompare(word) == .orderedSame }
        guard let text = entry?.text, let definition = parse(text) else { return nil }
        cache[word] = definition
        return definition
    }

    /// Parses entry text such as
    /// `stubborn | BrE ˈstʌb(ə)n, AmE … | adjective ① (difficult to influence) 执拗的 zhíniù de ‹person›; 倔强的 …▸ example ② …`
    /// into `adj.` and `执拗的，倔强的；难开的`: the Chinese terms of the first senses, without pinyin or examples.
    func parse(_ text: String) -> WordDefinition? {
        let fields = text.components(separatedBy: " | ")
        guard fields.count >= 3 else { return nil }
        var body = fields.dropFirst(2).joined(separator: " | ").trimmingCharacters(in: .whitespaces)
        if body.hasPrefix("A. ") {
            body.removeFirst(3)
        }

        // The part of speech starts the body, or follows the headword when the
        // entry has several (`upgrade A. transitive verb | … | ① …`).
        let headField = fields[0]
        let partOfSpeech = partsOfSpeech.first { body.hasPrefix($0.name) }?.abbreviation
            ?? partsOfSpeech.first { headField.hasSuffix(" " + $0.name) }?.abbreviation

        // Senses are numbered ① ② …; an entry with a single sense has no number.
        let senseTexts = body.components(separatedBy: CharacterSet(charactersIn: "①②③④⑤⑥⑦⑧⑨⑩"))
        let candidates = senseTexts.count > 1 ? Array(senseTexts.dropFirst()) : senseTexts
        var seen = Set<String>()
        var senses: [String] = []
        for sense in candidates {
            // Drop examples after `▸`, the next part of speech (`B. …`), and English notes.
            var gloss = sense.components(separatedBy: "▸").first ?? sense
            if let range = gloss.range(of: #"\s[B-H]\.\s"#, options: .regularExpression) {
                gloss = String(gloss[..<range.lowerBound])
            }
            gloss = gloss
                .replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"‹[^›]*›"#, with: "", options: .regularExpression)
            let terms = matches(of: #"[（\p{Han}][\p{Han}（）…，、]*"#, in: gloss)
                .filter { seen.insert($0).inserted }
                .prefix(maxTermsPerSense)
            if !terms.isEmpty {
                senses.append(terms.joined(separator: "，"))
            }
            if senses.count == maxSenses {
                break
            }
        }
        guard !senses.isEmpty else { return nil }
        return WordDefinition(partOfSpeech: partOfSpeech, meaning: senses.joined(separator: "；"))
    }

    // MARK: Private

    private let dictionaryName = "牛津英汉汉英词典"
    private let maxSenses = 2
    private let maxTermsPerSense = 3
    /// How long a missing dictionary is remembered before checking again, so a
    /// dictionary installed while the app runs is picked up without a restart.
    private let recheckInterval: TimeInterval = 60

    private let partsOfSpeech: [(name: String, abbreviation: String)] = [
        ("transitive verb", "v."), ("intransitive verb", "v."), ("verb", "v."),
        ("noun", "n."), ("adjective", "adj."), ("adverb", "adv."), ("preposition", "prep."),
        ("conjunction", "conj."), ("pronoun", "pron."), ("interjection", "int."),
        ("abbreviation", "abbr."), ("determiner", "det."), ("prefix", "prefix"), ("suffix", "suffix"),
    ]

    private var cache: [String: WordDefinition] = [:]
    private var loadedDictionary: TTTDictionary?
    private var lastLoadAttempt: Date?

    private var dictionary: TTTDictionary? {
        if let loadedDictionary {
            return loadedDictionary
        }
        if let lastLoadAttempt, Date().timeIntervalSince(lastLoadAttempt) < recheckInterval {
            return nil
        }
        lastLoadAttempt = Date()
        loadedDictionary = TTTDictionary(named: dictionaryName)
        return loadedDictionary
    }

    private func matches(of pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0]) }
        }
    }
}
