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

    /// The gloss of the entry for `word` whose senses mention `chinese`, such as the
    /// `银行` entry of `bank` rather than its `岸` entry; `nil` when no entry does.
    func definition(for word: String, mentioning chinese: String) -> WordDefinition? {
        guard let dictionary else { return nil }
        return dictionary.entries(forSearchTerm: word)
            .filter { $0.headword.caseInsensitiveCompare(word) == .orderedSame }
            .lazy
            .compactMap { self.parse($0.text) }
            .first { $0.meaning.contains(chinese) }
    }

    /// English words for Chinese `text` from the Chinese-English half of the dictionary,
    /// such as `stubborn` (adj.) and `stick to` (v.) for `固执`, in the dictionary's order.
    func translations(for text: String) -> [(word: String, partOfSpeech: String?)] {
        guard let dictionary else { return [] }
        // Chinese headwords carry their pinyin, such as `固执  gùzhí`.
        let entries = dictionary.entries(forSearchTerm: text)
            .filter { $0.headword.split(separator: " ").first.map(String.init) == text }
        var seen = Set<String>()
        return entries.flatMap { parseChinese($0.text) }
            .filter { seen.insert($0.word.lowercased()).inserted }
    }

    /// Parses Chinese entry text such as
    /// `固执 ɡùzhí A. adjective stubborn▸ 例句… B. verb stick to→ 固执己见`
    /// or `打 1 dǎ verb ① （击打） beat▸ … ② （打碎） break▸ …`
    /// into English translations with their parts of speech, leaving out examples and cross-references.
    func parseChinese(_ text: String) -> [(word: String, partOfSpeech: String?)] {
        let names = chinesePartsOfSpeech.map(\.name).joined(separator: "|")
        guard let regex = try? NSRegularExpression(pattern: "(?:^|\\s)(?:[A-H]\\.\\s+)?(\(names))\\s")
        else { return [] }
        let nsText = text as NSString
        let sections = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
        var results: [(word: String, partOfSpeech: String?)] = []
        for (index, match) in sections.enumerated() {
            let name = nsText.substring(with: match.range(at: 1))
            let partOfSpeech = chinesePartsOfSpeech.first { $0.name == name }?.abbreviation
            let start = match.range.location + match.range.length
            let end = index + 1 < sections.count ? sections[index + 1].range.location : nsText.length
            let body = nsText.substring(with: NSRange(location: start, length: max(end - start, 0)))

            let senseTexts = body.components(separatedBy: CharacterSet(charactersIn: "①②③④⑤⑥⑦⑧⑨⑩"))
            let senses = senseTexts.count > 1 ? Array(senseTexts.dropFirst()) : senseTexts
            for sense in senses {
                var gloss = sense.components(separatedBy: "▸").first ?? sense
                gloss = gloss.components(separatedBy: "→").first ?? gloss
                gloss = gloss
                    .replacingOccurrences(of: #"（[^）]*）"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
                    .replacingOccurrences(of: #"‹[^›]*›"#, with: "", options: .regularExpression)
                for item in gloss.components(separatedBy: CharacterSet(charactersIn: ";,；，")) {
                    var word = item.trimmingCharacters(in: .whitespaces)
                    // Register labels such as `informal` come before the translation.
                    for label in registerLabels where word.hasPrefix(label + " ") {
                        word = String(word.dropFirst(label.count + 1))
                    }
                    let isEnglish = word.range(of: #"^[A-Za-z][A-Za-z'’ \-]*$"#, options: .regularExpression) != nil
                    if isEnglish, word.split(separator: " ").count <= 4 {
                        results.append((word, partOfSpeech))
                    }
                }
            }
        }
        return results
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

    private let chinesePartsOfSpeech: [(name: String, abbreviation: String?)] = [
        ("measure word", "n."), ("adjective", "adj."), ("adverb", "adv."), ("noun", "n."), ("verb", "v."),
        ("idiom", nil), ("preposition", "prep."), ("conjunction", "conj."), ("pronoun", "pron."),
        ("numeral", "num."), ("interjection", "int."), ("particle", nil), ("phrase", nil),
    ]
    private let registerLabels = ["informal", "formal", "literary", "figurative", "literal", "dialect", "written"]

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
