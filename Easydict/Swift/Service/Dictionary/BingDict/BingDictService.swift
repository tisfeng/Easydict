//
//  BingDictService.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/04.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - BingDictService

/// Query service that looks up words in Bing Dictionary (`cn.bing.com/dict`).
///
/// Fetches the anonymous, server-rendered dict page and maps its content into
/// the native word result — phonetics, quick senses, word forms, collocations,
/// synonyms/antonyms and the numbered bilingual senses — so the card renders
/// with the app's native result view and needs no cookie or token setup.
@objc(EZBingDictService)
@objcMembers
class BingDictService: QueryService, @unchecked Sendable {
    // MARK: Internal

    // MARK: - QueryService overrides

    override func serviceType() -> ServiceType {
        .bingDict
    }

    override func name() -> String {
        NSLocalizedString("service.bing_dict.name", comment: "")
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    /// The dict page only carries EN-CN content.
    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        [.dictionary]
    }

    override func shouldAutoQuery(withText text: String) -> Bool {
        DictionarySupport.isSingleEnglishWord(text)
    }

    /// Validation uses an English headword; the default Chinese sample is
    /// rejected by the English-only guard below.
    override func validationQuery() -> (text: String, from: Language, to: Language) {
        ("hello", .english, .simplifiedChinese)
    }

    /// Only English source and Chinese targets are served; listing more
    /// languages would offer the service for pairs it always rejects.
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let languages: [Any] = [
            Language.auto, "auto-detect",
            Language.simplifiedChinese, "zh-Hans",
            Language.traditionalChinese, "zh-Hant",
            Language.english, "en",
        ]
        let ordered = MMOrderedDictionary()
        for index in stride(from: 0, to: languages.count, by: 2) {
            if let key = languages[index] as? NSObject,
               let value = languages[index + 1] as? NSObject {
                ordered.setObject(value, forKey: key)
            }
        }
        return ordered
    }

    /// Conversion happens after a successful English lookup, so Chinese input
    /// is rejected instead of being handled by the generic Chinese prehandler.
    override func autoConvertTraditionalChinese() -> Bool {
        false
    }

    override func wordLink(_ queryModel: QueryModel) -> String? {
        let encoded = DictionarySupport.percentEncodedQueryValue(queryModel.queryText)
        return "\(BingDictRequest.baseURLString)?q=\(encoded)"
    }

    // MARK: - Lookup

    @nonobjc
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        guard from == .english,
              to == .simplifiedChinese || to == .traditionalChinese,
              DictionarySupport.isSingleEnglishWord(text)
        else {
            throw QueryError(type: .noResult)
        }

        let html = try await BingDictRequest.fetchPage(for: text)
        guard let entry = BingDictHTMLParser.parse(html) else {
            throw QueryError(type: .noResult)
        }

        let wordResult = makeWordResult(entry: entry, word: text)
        let plainText = entry.plainText

        try updateResultLock.withLock {
            try Task.checkCancellation()
            if let generation = Self.queryGeneration, generation != resultGeneration {
                throw CancellationError()
            }

            result?.wordResult = wordResult
            result?.innerTexts = [plainText]
            result?.copiedText = plainText
            result?.translatedResults = entry.bestTranslation.map { [$0] } ?? []

            // Convert here rather than only in the view controller so direct
            // callers such as /translate receive the same Traditional result.
            if to == .traditionalChinese {
                result?.convertToTraditionalChineseResult()
            }
        }

        return result ?? QueryResult()
    }

    /// Maps quick and numbered senses into `parts`, and word forms, collocations,
    /// synonyms and antonyms into the native structured fields used by the card
    /// and Anki. One part per numbered sense keeps senses on separate lines.
    func makeWordResult(entry: BingDictWordEntry, word: String) -> EZTranslateWordResult {
        let wordResult = EZTranslateWordResult()

        var phonetics: [EZWordPhonetic] = []
        if let value = entry.phoneticUS, !value.isEmpty {
            phonetics.append(Self.phonetic(name: "us_phonetic", value: value, word: word, accent: "us"))
        }
        if let value = entry.phoneticUK, !value.isEmpty {
            phonetics.append(Self.phonetic(name: "uk_phonetic", value: value, word: word, accent: "uk"))
        }
        if !phonetics.isEmpty {
            wordResult.phonetics = phonetics
        }

        var parts: [EZTranslatePart] = []
        var orderedParts: [EZTranslatePart] = []
        func makePart(_ label: String, _ means: [String]) -> EZTranslatePart {
            let part = EZTranslatePart()
            part.part = label
            part.means = means
            return part
        }

        func appendPart(_ label: String, _ means: [String]) {
            guard !means.isEmpty else { return }
            let part = makePart(label, means)
            parts.append(part)
            orderedParts.append(part)
        }

        func appendOrderedOnly(_ label: String, _ means: [String]) {
            guard !means.isEmpty else { return }
            orderedParts.append(makePart(label, means))
        }

        for row in entry.quickRows {
            appendPart(row.label, [row.values])
        }

        if !entry.wordForms.isEmpty {
            let forms = Self.groupedWordForms(entry.wordForms)
                .map { "\($0.label): \($0.values.joined(separator: ", "))" }
                .joined(separator: "    ")
            appendOrderedOnly(NSLocalizedString("service.dictionary.section.word_forms", comment: ""), [forms])
        }

        for collocation in entry.collocations {
            appendOrderedOnly(collocation.label, [collocation.items.joined(separator: ", ")])
        }

        for (heading, groups) in [
            (NSLocalizedString("synonyms", comment: ""), entry.synonyms),
            (NSLocalizedString("antonyms", comment: ""), entry.antonyms),
        ] where !groups.isEmpty {
            appendOrderedOnly("", [heading])
            for group in groups {
                appendOrderedOnly(group.label, [group.items.joined(separator: ", ")])
            }
        }

        let showsPos = entry.senseGroups.count > 1
        for group in entry.senseGroups {
            for sense in group.senses where !sense.chinese.isEmpty || !sense.english.isEmpty {
                let head = [sense.grammar, sense.complement]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                let body = [sense.chinese, sense.english]
                    .filter { !$0.isEmpty }
                    .joined(separator: "  ")
                let text = head.isEmpty ? body : "\(head)  \(body)"
                appendPart(showsPos ? "\(group.pos) \(sense.index)" : sense.index, [text])
            }
        }

        if !parts.isEmpty {
            wordResult.parts = parts
        }
        if !orderedParts.isEmpty {
            wordResult.orderedParts = orderedParts
        }

        if !entry.wordForms.isEmpty {
            wordResult.exchanges = Self.groupedWordForms(entry.wordForms).map { group in
                let exchange = EZTranslateExchange()
                exchange.name = group.label
                exchange.words = group.values
                return exchange
            }
        }

        // Native related-word sections supply localized headings and clickable
        // links, and keep these values available to structured Anki fields.
        wordResult.collocation = Self.collocationParts(entry.collocations)
        wordResult.synonyms = Self.collocationParts(entry.synonyms)
        wordResult.antonyms = Self.collocationParts(entry.antonyms)

        return wordResult
    }

    // MARK: Private

    /// Merge repeated labels (`复数：formulas`, `复数：formulae`) into one row.
    private static func groupedWordForms(
        _ forms: [BingDictWordForm]
    )
        -> [(label: String, values: [String])] {
        var grouped: [(label: String, values: [String])] = []
        for form in forms {
            if let index = grouped.firstIndex(where: { $0.label == form.label }) {
                grouped[index].values.append(form.value)
            } else {
                grouped.append((form.label, [form.value]))
            }
        }
        return grouped
    }

    private static func collocationParts(_ groups: [BingDictCollocation]) -> [EZTranslatePart]? {
        guard !groups.isEmpty else { return nil }
        return groups.map { group in
            let part = EZTranslatePart()
            part.part = group.label
            part.means = group.items
            return part
        }
    }

    private static func phonetic(
        name: String,
        value: String,
        word: String,
        accent: String
    )
        -> EZWordPhonetic {
        let phonetic = EZWordPhonetic()
        phonetic.word = word
        phonetic.language = .english
        phonetic.name = NSLocalizedString(name, comment: "")
        phonetic.value = value
        phonetic.accent = accent
        return phonetic
    }
}
