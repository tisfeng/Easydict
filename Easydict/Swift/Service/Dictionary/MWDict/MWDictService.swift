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
/// verb divider, nested senses with examples and synonyms.
@objc(EZMWDictService)
@objcMembers
class MWDictService: QueryService, @unchecked Sendable {
    // MARK: Internal

    // MARK: - QueryService overrides

    override func serviceType() -> ServiceType {
        .merriamWebster
    }

    override func name() -> String {
        NSLocalizedString("service.mw_dict.name", comment: "")
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

    override func shouldAutoQuery(withText text: String) -> Bool {
        DictionarySupport.isSingleEnglishWord(text)
    }

    /// Validation uses an English headword; the default Chinese sample is
    /// rejected by the English-only guard below.
    override func validationQuery() -> (text: String, from: Language, to: Language) {
        ("hello", .english, .simplifiedChinese)
    }

    /// The API serves monolingual English definitions and ignores the target
    /// language, so every app language pair is accepted — otherwise users whose
    /// default target is Japanese or Spanish would get an unsupported-language
    /// error before the lookup runs.
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let ordered = MMOrderedDictionary()
        for language in EZLanguageManager.shared().allLanguages {
            ordered.setObject(language as NSString, forKey: language as NSString)
        }
        return ordered
    }

    override func wordLink(_ queryModel: QueryModel) -> String? {
        let encoded = DictionarySupport.percentEncodedQueryValue(queryModel.queryText)
        return "https://www.merriam-webster.com/dictionary/\(encoded)"
    }

    override func configurationListItems() -> Any? {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.mwDictAPIKey, .mwLearnersAPIKey],
            requiredKeys: [.mwDictAPIKey]
        ) {
            SecureInputCell(
                textFieldTitleKey: "service.configuration.mw_dict.api_key.title",
                key: .mwDictAPIKey
            )
            SecureInputCell(
                textFieldTitleKey: "service.configuration.mw_dict.learners_api_key.title",
                key: .mwLearnersAPIKey
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

        let sentences = try await fetchLearnerSentences(word: text)

        let wordResult = makeWordResult(entry: entry, word: text, sentences: sentences)
        let plainText = entry.plainText

        try updateResultLock.withLock {
            try Task.checkCancellation()
            if let generation = Self.queryGeneration, generation != resultGeneration {
                throw CancellationError()
            }

            result?.wordResult = wordResult
            result?.innerTexts = [plainText]
            result?.copiedText = plainText
            result?.translatedResults = entry.bestTranslation.map { [$0] }
        }

        return result ?? QueryResult()
    }

    /// Mirrors the official entry order: part of speech → inflections → sections
    /// and nested senses with their examples.
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
            phonetic.name = NSLocalizedString("us_phonetic", comment: "")
            phonetic.value = pronunciation
            phonetic.accent = "us"
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

        for section in entry.sections {
            if !section.label.isEmpty {
                appendPart("", [section.label])
            }
            for sense in section.senses {
                let layout = Self.senseLayout(sense.number)
                let labelIndent = String(repeating: " ", count: layout.level * 4)
                appendPart(labelIndent + layout.label, [sense.definition])

                let exampleIndent = labelIndent + String(repeating: " ", count: 8)
                for example in sense.examples {
                    appendPart(exampleIndent + "⦁", [example])
                }
            }
        }

        for runOn in entry.runOns {
            appendPart("", [runOn])
        }

        // The site's "Examples of … in a Sentence" block comes from the Learner's
        // Dictionary; it appears only when that reference is subscribed.
        if !sentences.isEmpty {
            let heading = NSLocalizedString("service.mw_dict.section.examples_in_a_sentence", comment: "")
            appendPart("", [Self.boldLatinText(heading)])
            for sentence in sentences {
                appendPart("        ⦁", [sentence])
            }
        }

        if !parts.isEmpty {
            wordResult.parts = parts
        }

        if !entry.wordForms.isEmpty {
            let inflections = EZTranslateExchange()
            inflections.name = NSLocalizedString("service.dictionary.section.word_forms", comment: "")
            inflections.words = entry.wordForms
            wordResult.exchanges = [inflections]
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

    private var learnerAPIKey: String {
        Defaults[.mwLearnersAPIKey]
    }

    /// The native card has no bold text style for section headings, so Latin
    /// letters use mathematical bold glyphs; other scripts stay unchanged.
    private static func boldLatinText(_ text: String) -> String {
        let scalars = text.unicodeScalars.map { scalar -> UnicodeScalar in
            switch scalar.value {
            case 65 ... 90:
                return UnicodeScalar(0x1D5D4 + scalar.value - 65) ?? scalar
            case 97 ... 122:
                return UnicodeScalar(0x1D5EE + scalar.value - 97) ?? scalar
            default:
                return scalar
            }
        }
        return String(String.UnicodeScalarView(scalars))
    }

    /// Turns the fully-qualified number into the site's nested layout:
    /// `1 a` at the top level, `b` one level in, `(2)` one level deeper.
    private static func senseLayout(_ number: String) -> (label: String, level: Int) {
        let components = number.split(separator: " ").map(String.init)

        if let parenthesized = components.last, parenthesized.hasPrefix("(") {
            if parenthesized == "(1)" {
                let isQualified = components.first?.first?.isNumber == true
                let label = isQualified ? components.dropFirst().joined(separator: " ") : number
                return (label, 1)
            }
            return (parenthesized, 2)
        }

        if components.count == 2, components[1].count == 1, components[1] != "a" {
            return (components[1], 1)
        }

        return (number, 0)
    }

    /// Best-effort fetch of the site's full-sentence examples. The reference is a
    /// separate subscription; an invalid key or missing reference yields no block.
    ///
    /// The short timeout keeps this optional request off the result critical
    /// path: without it a slow Learner endpoint would hold back the already
    /// parsed Collegiate card for the full request timeout.
    private func fetchLearnerSentences(word: String) async throws -> [String] {
        do {
            let data = try await MWDictRequest.fetchEntryJSON(
                for: word,
                apiKey: learnerAPIKey.isEmpty ? apiKey : learnerAPIKey,
                timeout: 5,
                reference: "learners"
            )
            return MWDictAPIParser.extractSentences(data)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return []
        }
    }
}
