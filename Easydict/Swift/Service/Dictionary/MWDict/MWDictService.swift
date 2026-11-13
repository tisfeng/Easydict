//
//  MWDictService.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/09.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults
import Foundation
import SwiftUI

// MARK: - MWDictService

/// Query service backed by the Merriam-Webster Collegiate API.
///
/// The dictionary website is protected by a Cloudflare bot challenge, so the
/// service uses the official API with a user-provided free key. The card mirrors
/// the site: headword part of speech, pronunciation, inflections, one section per
/// verb divider, numbered senses with examples, synonyms and first known use.
@objc(EZMWDictService)
@objcMembers
class MWDictService: QueryService, @unchecked Sendable {
    // MARK: Internal

    // MARK: - QueryService overrides

    override func serviceType() -> ServiceType {
        .merriamWebster
    }

    override func name() -> String {
        NSLocalizedString("merriam_webster", comment: "")
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .userProvided
    }

    override func hasPrivateAPIKey() -> Bool {
        !apiKey.isEmpty
    }

    override func link() -> String? {
        "https://www.merriam-webster.com"
    }

    /// The API returns English definitions; it only serves single English headwords.
    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        [.dictionary]
    }

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

    override func wordLink(_ queryModel: QueryModel) -> String? {
        let encoded = DictionarySupport.percentEncodedQueryValue(queryModel.queryText)
        return "https://www.merriam-webster.com/dictionary/\(encoded)"
    }

    override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.mwDictAPIKey]) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.mw_dict.api_key.title",
                key: .mwDictAPIKey
            )
        }
    }

    // MARK: - Lookup

    @nonobjc
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        guard from == .english, DictionarySupport.isSingleEnglishWord(text) else {
            throw QueryError(type: .noResult)
        }
        guard !apiKey.isEmpty else {
            throw QueryError.error(
                type: .api,
                message: NSLocalizedString("service.configuration.mw_dict.api_key.title", comment: "")
            )
        }

        let data = try await MWDictRequest.fetchEntryJSON(for: text, apiKey: apiKey)
        guard let entry = MWDictAPIParser.parse(data) else {
            throw QueryError(type: .noResult)
        }

        let sentences = await fetchLearnerSentences(word: text)

        result?.wordResult = makeWordResult(entry: entry, word: text, sentences: sentences)

        let plainText = entry.plainText
        result?.innerTexts = [plainText]
        result?.copiedText = plainText
        result?.translatedResults = entry.bestTranslation.map { [$0] }

        return result ?? QueryResult()
    }

    /// Mirrors the official entry order: part of speech → inflections → sections
    /// and numbered senses → first known use → etymology.
    func makeWordResult(
        entry: MWDictEntry,
        word: String,
        sentences: [String] = []
    )
        -> EZTranslateWordResult {
        let wordResult = EZTranslateWordResult()

        if let pronunciation = entry.pronunciations.first {
            let phonetic = EZWordPhonetic()
            phonetic.word = word
            phonetic.language = .english
            phonetic.name = "US"
            phonetic.value = pronunciation
            phonetic.accent = "US"
            wordResult.phonetics = [phonetic]
        }

        var parts: [EZTranslatePart] = []
        func appendPart(_ label: String, _ means: [String]) {
            guard !means.isEmpty else { return }
            let part = EZTranslatePart()
            part.part = label
            part.means = means
            parts.append(part)
        }

        if entry.sections.allSatisfy({ $0.label.isEmpty }), !entry.partOfSpeech.isEmpty {
            appendPart("", [entry.partOfSpeech])
        }

        // The site lists the inflections as a bare line under the headword;
        // a part label would be turned into an abbreviation by the model.
        if !entry.wordForms.isEmpty {
            appendPart("", [entry.wordForms.joined(separator: "; ")])
        }

        for section in entry.sections {
            if !section.label.isEmpty {
                appendPart("", [section.label])
            }
            for sense in section.senses {
                appendPart(sense.number, [sense.definition])
                for example in sense.examples {
                    appendPart("", ["— \(example)"])
                }
            }
        }

        for runOn in entry.runOns {
            appendPart("", [runOn])
        }

        // The site's "Examples of … in a Sentence" block comes from the Learner's
        // Dictionary; it appears only when that reference is subscribed.
        if !sentences.isEmpty {
            appendPart("", ["Examples in a Sentence"])
            for sentence in sentences {
                appendPart("", ["— \(sentence)"])
            }
        }

        if !parts.isEmpty {
            wordResult.parts = parts
        }

        if !entry.synonyms.isEmpty {
            let synonyms = EZTranslatePart()
            synonyms.part = ""
            synonyms.means = entry.synonyms
            wordResult.synonyms = [synonyms]
        }

        return wordResult
    }

    // MARK: Private

    private var apiKey: String {
        Defaults[.mwDictAPIKey]
    }

    /// Best-effort fetch of the site's full-sentence examples. The reference is a
    /// separate subscription; an invalid key or missing reference yields no block.
    private func fetchLearnerSentences(word: String) async -> [String] {
        do {
            let data = try await MWDictRequest.fetchEntryJSON(
                for: word,
                apiKey: apiKey,
                reference: "learners"
            )
            return MWDictAPIParser.extractSentences(data)
        } catch {
            return []
        }
    }
}
