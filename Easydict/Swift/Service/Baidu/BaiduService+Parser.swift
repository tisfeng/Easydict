//
//  BaiduService+Parser.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension BaiduService {
    func parseDictionaryResult(
        _ response: EZBaiduTranslateResponse,
        result: EZQueryResult
    ) {
        guard let simpleMeans = response.dict_result?.simple_means else { return }

        let wordResult = EZTranslateWordResult()

        appendTags(from: simpleMeans.tags, to: wordResult)

        if let symbol = simpleMeans.symbols.first {
            let phonetics = buildPhonetics(
                from: symbol,
                language: queryModel.queryFromLanguage,
                queryText: queryModel.queryText
            )
            if !phonetics.isEmpty {
                wordResult.phonetics = phonetics
            }

            let parts = buildTranslateParts(from: symbol)
            if !parts.isEmpty {
                wordResult.parts = parts
            }
        }

        let exchanges = buildExchanges(from: simpleMeans.exchange)
        if !exchanges.isEmpty {
            wordResult.exchanges = exchanges
        }

        let simpleWords = buildSimpleWords(from: simpleMeans.symbols.first?.parts.first)
        if !simpleWords.isEmpty {
            wordResult.simpleWords = simpleWords
        }

        let wordMeans = simpleMeans.word_means
        if let first = wordMeans.first {
            result.translatedResults = [(first as NSString).ns_trim() as String]
        }

        if wordResult.parts != nil || wordResult.simpleWords != nil {
            result.wordResult = wordResult
        }
    }

    func parseTranslationResult(
        _ response: EZBaiduTranslateResponse,
        result: EZQueryResult
    ) {
        let translatedResults: [String] = response.trans_result.data.compactMap { item in
            let trimmed = item.dst.trim()
            if item.prefixWrap {
                return "\n\(trimmed)"
            }
            return trimmed
        }

        if !translatedResults.isEmpty {
            result.translatedResults = translatedResults
        }
    }

    /// Merge response tags into the given word result.
    private func appendTags(from tags: EZBaiduTranslateResponseTags?, to wordResult: EZTranslateWordResult) {
        guard let tags else { return }

        var combined: [String] = []
        if let core = tags.core { combined.append(contentsOf: core) }
        if let other = tags.other {
            combined.append(contentsOf: other.filter { !$0.isEmpty })
        }

        if !combined.isEmpty {
            wordResult.tags = combined
        }
    }

    /// Build phonetics for the first dictionary symbol.
    private func buildPhonetics(
        from symbol: EZBaiduTranslateResponseSymbol,
        language: Language,
        queryText: String
    )
        -> [EZWordPhonetic] {
        var phonetics: [EZWordPhonetic] = []

        if !symbol.ph_am.isEmpty {
            let phonetic = EZWordPhonetic()
            phonetic.name = NSLocalizedString("us_phonetic", comment: "")
            phonetic.language = language
            phonetic.accent = "us"
            phonetic.word = queryText
            phonetic.value = symbol.ph_am
            phonetic.speakURL = getAudioURL(with: queryText, langCode: "en")
            phonetics.append(phonetic)
        }

        if !symbol.ph_en.isEmpty {
            let phonetic = EZWordPhonetic()
            phonetic.name = NSLocalizedString("uk_phonetic", comment: "")
            phonetic.language = language
            phonetic.accent = "uk"
            phonetic.word = queryText
            phonetic.value = symbol.ph_en
            phonetic.speakURL = getAudioURL(with: queryText, langCode: "uk")
            phonetics.append(phonetic)
        }

        return phonetics
    }

    /// Build translate parts from Baidu dictionary response.
    private func buildTranslateParts(from symbol: EZBaiduTranslateResponseSymbol) -> [EZTranslatePart] {
        symbol.parts.compactMap { part -> EZTranslatePart? in
            let translatePart = EZTranslatePart()
            if let partText = part.part, !partText.isEmpty {
                translatePart.part = partText
            } else if let partName = part.part_name, !partName.isEmpty {
                translatePart.part = partName
            }
            translatePart.means = []
            if let means = part.means as? [String], !means.isEmpty {
                translatePart.means = means
            }
            return translatePart.means.isEmpty ? nil : translatePart
        }
    }

    /// Build word exchanges list with localized labels.
    private func buildExchanges(from exchange: EZBaiduTranslateResponseExchange?) -> [EZTranslateExchange] {
        guard let exchange else { return [] }

        let entries: [(nameKey: String, words: [String]?)] = [
            ("singular", exchange.word_third),
            ("plural", exchange.word_pl),
            ("comparative", exchange.word_er),
            ("superlative", exchange.word_est),
            ("past", exchange.word_past),
            ("past_participle", exchange.word_done),
            ("present_participle", exchange.word_ing),
            ("root", exchange.word_proto),
        ]

        return entries.compactMap { entry in
            guard let words = entry.words, !words.isEmpty else { return nil }
            let exchange = EZTranslateExchange()
            exchange.name = NSLocalizedString(entry.nameKey, comment: "")
            exchange.words = words
            return exchange
        }
    }

    /// Build simplified related words list from the first dictionary part.
    private func buildSimpleWords(from part: EZBaiduTranslateResponsePart?) -> [EZTranslateSimpleWord] {
        guard let means = part?.means as? [[String: Any]] else { return [] }

        let simpleWords: [EZTranslateSimpleWord] = means.compactMap { item in
            guard item["isSeeAlso"] == nil else { return nil }
            guard let word = item["text"] as? String, !word.isEmpty else { return nil }

            let simpleWord = EZTranslateSimpleWord()
            simpleWord.word = word
            let part = (item["part"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "misc."
            simpleWord.part = part
            if let wordMeans = item["means"] as? [String] {
                simpleWord.means = wordMeans
            }
            return simpleWord
        }

        return simpleWords.sorted { lhs, rhs in
            if rhs.part == "misc." {
                return true
            }
            if lhs.part == "misc." {
                return false
            }
            return (lhs.part ?? "") < (rhs.part ?? "")
        }
    }
}
