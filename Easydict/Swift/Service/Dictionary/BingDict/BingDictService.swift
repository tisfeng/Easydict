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
        NSLocalizedString("bing_dict", comment: "")
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

    /// The page content is simplified Chinese; let the app convert it for
    /// traditional Chinese targets.
    override func autoConvertTraditionalChinese() -> Bool {
        true
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

        result?.wordResult = makeWordResult(entry: entry, word: text)

        let plainText = entry.plainText
        result?.innerTexts = [plainText]
        result?.copiedText = plainText
        result?.translatedResults = entry.bestTranslation.map { [$0] } ?? []

        return result ?? QueryResult()
    }

    /// Mirrors the official page structure and order:
    /// quick senses → word forms → collocations → synonyms/antonyms → numbered senses.
    /// Every section is a separate `EZTranslatePart` because the native card joins
    /// one part's lines with "; " — one part per numbered sense keeps them on
    /// their own lines.
    func makeWordResult(entry: BingDictWordEntry, word: String) -> EZTranslateWordResult {
        let wordResult = EZTranslateWordResult()

        var phonetics: [EZWordPhonetic] = []
        if let value = entry.phoneticUS, !value.isEmpty {
            phonetics.append(Self.phonetic(name: "us_phonetic", value: value, word: word, accent: "US"))
        }
        if let value = entry.phoneticUK, !value.isEmpty {
            phonetics.append(Self.phonetic(name: "uk_phonetic", value: value, word: word, accent: "UK"))
        }
        if !phonetics.isEmpty {
            wordResult.phonetics = phonetics
        }

        var parts: [EZTranslatePart] = []
        func appendPart(_ label: String, _ means: [String]) {
            guard !means.isEmpty else { return }
            let part = EZTranslatePart()
            part.part = label
            part.means = means
            parts.append(part)
        }

        for row in entry.quickRows {
            appendPart(row.label, [row.values])
        }

        if !entry.wordForms.isEmpty {
            let forms = Self.groupedWordForms(entry.wordForms)
                .map { "\($0.label): \($0.values.joined(separator: ", "))" }
                .joined(separator: "    ")
            appendPart("变形", [forms])
        }

        for collocation in entry.collocations {
            appendPart(collocation.label, [collocation.items.joined(separator: ", ")])
        }

        if !entry.synonyms.isEmpty {
            appendPart("同义词", entry.synonyms.map { "\($0.label)  \($0.items.joined(separator: ", "))" })
        }
        if !entry.antonyms.isEmpty {
            appendPart("反义词", entry.antonyms.map { "\($0.label)  \($0.items.joined(separator: ", "))" })
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
