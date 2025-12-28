//
//  BingService+Translate.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - BingService + Translate

extension BingService {
    // MARK: - Bing Translate

    func bingTranslate(
        _ text: String,
        useDictQuery: Bool,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        isDictQueryResult = false

        if useDictQuery {
            bingRequest.translateTextFromDict(text: text) { [weak self] json, error in
                guard let self = self else { return }

                parseBingDictTranslate(json, word: text) { dictResult, dictError in
                    if error != nil || dictError != nil {
                        self.bingTranslate(text, useDictQuery: false, from: from, to: to, completion: completion)
                    } else {
                        self.isDictQueryResult = true
                        completion(dictResult, nil)
                    }
                }
            }
            return
        }

        let trimmedText = maxTextLength(text, fromLanguage: from)
        let fromCode = languageCode(forLanguage: from) ?? ""
        let toCode = languageCode(forLanguage: to) ?? ""

        bingRequest.translateText(
            text: trimmedText,
            from: fromCode,
            to: toCode
        ) { [weak self] translateData, lookupData, translateError, lookupError in
            guard let self = self else { return }

            do {
                if let translateError = translateError {
                    result.error = QueryError(type: .api, message: translateError.localizedDescription)
                    logError("bing translate error: \(translateError)")
                } else {
                    var needRetry = false
                    let error = processTranslateResult(
                        translateData,
                        text: trimmedText,
                        from: from,
                        to: to,
                        needRetry: &needRetry
                    )

                    // canRetry is used to avoid recursive calls, code 205 only retry once.
                    if canRetry, needRetry {
                        canRetry = false
                        bingTranslate(text, useDictQuery: false, from: from, to: to, completion: completion)
                        return
                    }
                    canRetry = true

                    if let error = error {
                        result.error = QueryError(type: .api, message: error.localizedDescription)
                        completion(result, error)
                        return
                    }

                    if let lookupError = lookupError {
                        logError("bing lookup error: \(lookupError)")
                    } else {
                        processWordSimpleWordAndPart(lookupData)
                    }
                }
                completion(result, translateError)
            }
        }
    }

    // MARK: - Process Translate Result

    private func processTranslateResult(
        _ translateData: Data?,
        text: String,
        from: Language,
        to: Language,
        needRetry: inout Bool
    )
        -> Error? {
        guard let translateData = translateData, !translateData.isEmpty else {
            return QueryError(type: .api, message: "bing translate data is empty")
        }

        guard let json = try? JSONSerialization.jsonObject(with: translateData),
              let jsonArray = json as? [[String: Any]]
        else {
            var message = "bing json parse failed"
            if let dict = try? JSONSerialization.jsonObject(with: translateData) as? [String: Any] {
                // Through testing, 205 should be token invalid, need to re-fetch token
                if let statusCode = dict["statusCode"] as? Int, statusCode == 205 {
                    message = "token invalid, please try again or restart the app."
                    bingRequest.reset()
                    needRetry = true
                }
            }
            return QueryError(type: .api, message: message)
        }

        // Parse translate model
        let translateModels = jsonArray.compactMap { dict -> BingTranslateModel? in
            guard let data = try? JSONSerialization.data(withJSONObject: dict),
                  let model = try? JSONDecoder().decode(BingTranslateModel.self, from: data)
            else { return nil }
            return model
        }

        guard let translateModel = translateModels.first else {
            return QueryError(type: .api, message: "bing translate parse failed")
        }

        // Phonetic
        if jsonArray.count >= 2,
           let secondDict = jsonArray[safe: 1],
           let inputTransliteration = secondDict["inputTransliteration"] as? String {
            let phonetic = EZWordPhonetic()
            let fromLanguage = result.from as Language

            phonetic.name = fromLanguage == .english
                ? NSLocalizedString("us_phonetic", comment: "")
                : NSLocalizedString("chinese_phonetic", comment: "")

            // If text is too long, we don't show phonetic.
            if EZLanguageManager.shared().isShortWordLength(text, language: fromLanguage) {
                phonetic.value = inputTransliteration
                phonetic.language = fromLanguage
                phonetic.word = text

                if result.wordResult == nil {
                    result.wordResult = EZTranslateWordResult()
                }
                result.wordResult?.phonetics = [phonetic]
            }
        }

        result.raw = translateData as NSData
        result.translatedResults = translateModel.translations?.compactMap { $0.text }

        return nil
    }

    // MARK: - Process Word Simple Word and Part

    private func processWordSimpleWordAndPart(_ lookupData: Data?) {
        guard let lookupData = lookupData,
              let json = try? JSONSerialization.jsonObject(with: lookupData),
              let jsonArray = json as? [[String: Any]]
        else { return }

        let lookupModels = jsonArray.compactMap { dict -> BingLookupModel? in
            guard let data = try? JSONSerialization.data(withJSONObject: dict),
                  let model = try? JSONDecoder().decode(BingLookupModel.self, from: data)
            else { return nil }
            return model
        }

        guard let lookupModel = lookupModels.first else { return }

        let wordResult = result.wordResult ?? EZTranslateWordResult()

        // Group by posTag
        var tags: [String: [BingLookupTranslation]] = [:]
        for translation in lookupModel.translations ?? [] {
            guard let posTag = translation.posTag else { continue }
            if tags[posTag] == nil {
                tags[posTag] = []
            }
            tags[posTag]?.append(translation)
        }

        // Chinese to English
        let fromLang = result.from
        let toLang = result.to
        if fromLang == .simplifiedChinese || fromLang == .traditionalChinese,
           toLang == .english {
            var simpleWords: [EZTranslateSimpleWord] = []
            for (key, translations) in tags {
                for model in translations {
                    let simpleWord = EZTranslateSimpleWord()
                    simpleWord.part = key.lowercased()
                    simpleWord.word = model.displayTarget ?? ""
                    simpleWord.means = model.backTranslations?.compactMap { $0.displayText }
                    simpleWords.append(simpleWord)
                }
            }
            if !simpleWords.isEmpty {
                wordResult.simpleWords = simpleWords
            }
        } else {
            var parts: [EZTranslatePart] = []
            for (key, translations) in tags {
                let part = EZTranslatePart()
                part.part = key.lowercased()
                part.means = translations.compactMap { $0.displayTarget }
                parts.append(part)
            }
            if !parts.isEmpty {
                wordResult.parts = parts
            }
        }

        if wordResult.parts?.isEmpty == false || wordResult.simpleWords?.isEmpty == false {
            result.wordResult = wordResult
        }
    }

    // MARK: - Parse Bing Dict Translate

    private func parseBingDictTranslate(
        _ json: [String: Any]?,
        word: String,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        guard let json = json else {
            completion(result, QueryError(type: .api, message: "bing dict json is nil"))
            return
        }

        guard let value = json["value"] as? [[String: Any]], !value.isEmpty else {
            completion(result, QueryError(type: .api, message: "bing dict value is empty"))
            return
        }

        guard let meaningGroups = value.first?["meaningGroups"] as? [[String: Any]], !meaningGroups.isEmpty else {
            completion(result, QueryError(type: .api, message: "bing dict translate meaning groups is empty"))
            return
        }

        var parsedData = BingDictParsedData()
        let audioUrl = value.first?["pronunciationAudio"] as? [String: Any]

        for meaningGroup in meaningGroups {
            parseMeaningGroup(meaningGroup, word: word, audioUrl: audioUrl, into: &parsedData)
        }

        let wordResult = EZTranslateWordResult()
        result.wordResult = wordResult
        applyParsedData(parsedData, to: wordResult)

        // API has no field for translated result, get one from parts.
        if let means = wordResult.parts?.first?.means as? [String],
           let translateResult = means.first,
           !translateResult.isEmpty {
            result.translatedResults = [translateResult]
        }

        result.raw = json as NSDictionary
        completion(result, nil)
    }

    // MARK: - Parse Meaning Group

    private func parseMeaningGroup(
        _ meaningGroup: [String: Any],
        word: String,
        audioUrl: [String: Any]?,
        into data: inout BingDictParsedData
    ) {
        guard let partOfSpeech = meaningGroup["partsOfSpeech"] as? [[String: Any]],
              !partOfSpeech.isEmpty,
              let name = partOfSpeech.first?["name"] as? String,
              let description = partOfSpeech.first?["description"] as? String,
              let meanings = meaningGroup["meanings"] as? [[String: Any]],
              !meanings.isEmpty
        else { return }

        let richDefinitions = meanings.first?["richDefinitions"] as? [[String: Any]]
        let fragments = richDefinitions?.first?["fragments"] as? [[String: Any]]

        switch description {
        case "发音":
            if let phonetic = parsePhonetic(name: name, word: word, fragments: fragments, audioUrl: audioUrl) {
                data.phonetics.append(phonetic)
            }
        case "快速释义":
            data.parts.append(parsePart(name: name, fragments: fragments))
        case "词组":
            data.simpleWords.append(contentsOf: parsePhrases(richDefinitions: richDefinitions))
        case "分类词典":
            parseSynonymsAndAntonyms(meanings: meanings, name: name, into: &data)
        case "搭配":
            data.collocation.append(parseCollocation(name: name, fragments: fragments))
        default:
            break
        }

        if name == "变形" {
            data.exchanges.append(contentsOf: parseExchanges(fragments: fragments))
        }
    }

    // MARK: - Parse Phonetic

    private func parsePhonetic(
        name: String,
        word: String,
        fragments: [[String: Any]]?,
        audioUrl: [String: Any]?
    )
        -> EZWordPhonetic? {
        guard name == "US" || name == "UK" else { return nil }

        let contentUrl = audioUrl?["contentUrl"] as? String
        let phonetic = EZWordPhonetic()
        phonetic.word = word
        phonetic.language = .english
        phonetic.name = name == "US"
            ? NSLocalizedString("us_phonetic", comment: "")
            : NSLocalizedString("uk_phonetic", comment: "")
        phonetic.value = fragments?.first?["text"] as? String
        phonetic.speakURL = name == "US" ? contentUrl : contentUrl?.replacingOccurrences(of: "tom", with: "george")
        phonetic.accent = name
        return phonetic
    }

    // MARK: - Parse Part

    private func parsePart(name: String, fragments: [[String: Any]]?) -> EZTranslatePart {
        let part = EZTranslatePart()
        part.part = name
        part.means = fragments?.compactMap { $0["text"] as? String } ?? []
        return part
    }

    // MARK: - Parse Phrases

    private func parsePhrases(richDefinitions: [[String: Any]]?) -> [EZTranslateSimpleWord] {
        var simpleWords: [EZTranslateSimpleWord] = []
        for richDefinition in richDefinitions ?? [] {
            guard let examples = richDefinition["examples"] as? [String], examples.count == 2 else { continue }
            let simpleWord = EZTranslateSimpleWord()
            simpleWord.word = examples.first ?? ""
            simpleWord.means = examples.last?.components(separatedBy: ";")
            simpleWords.append(simpleWord)
        }
        return simpleWords
    }

    // MARK: - Parse Synonyms and Antonyms

    private func parseSynonymsAndAntonyms(
        meanings: [[String: Any]],
        name: String,
        into data: inout BingDictParsedData
    ) {
        let synonymMeans = (meanings.first?["synonyms"] as? [[String: Any]])?.compactMap { $0["name"] as? String }
        let antonymMeans = (meanings.first?["antonyms"] as? [[String: Any]])?.compactMap { $0["name"] as? String }

        if let synonymMeans = synonymMeans, !synonymMeans.isEmpty {
            let part = EZTranslatePart()
            part.part = name
            part.means = synonymMeans
            data.synonyms.append(part)
        }

        if let antonymMeans = antonymMeans, !antonymMeans.isEmpty {
            let part = EZTranslatePart()
            part.part = name
            part.means = antonymMeans
            data.antonyms.append(part)
        }
    }

    // MARK: - Parse Collocation

    private func parseCollocation(name: String, fragments: [[String: Any]]?) -> EZTranslatePart {
        let part = EZTranslatePart()
        part.part = name
        part.means = fragments?.compactMap { $0["text"] as? String } ?? []
        return part
    }

    // MARK: - Parse Exchanges

    private func parseExchanges(fragments: [[String: Any]]?) -> [EZTranslateExchange] {
        var exchanges: [EZTranslateExchange] = []
        for fragment in fragments ?? [] {
            guard let text = fragment["text"] as? String else { continue }
            let components = text.components(separatedBy: "：")
            if components.count == 2 {
                let exchange = EZTranslateExchange()
                exchange.name = components.first ?? ""
                exchange.words = [components.last ?? ""]
                exchanges.append(exchange)
            }
        }
        return exchanges
    }

    // MARK: - Apply Parsed Data

    private func applyParsedData(_ data: BingDictParsedData, to wordResult: EZTranslateWordResult) {
        if !data.phonetics.isEmpty { wordResult.phonetics = data.phonetics }
        if !data.parts.isEmpty { wordResult.parts = data.parts }
        if !data.exchanges.isEmpty { wordResult.exchanges = data.exchanges }
        if !data.simpleWords.isEmpty { wordResult.simpleWords = data.simpleWords }
        if !data.synonyms.isEmpty { wordResult.synonyms = data.synonyms }
        if !data.antonyms.isEmpty { wordResult.antonyms = data.antonyms }
        if !data.collocation.isEmpty { wordResult.collocation = data.collocation }
    }
}

// MARK: - BingDictParsedData

private struct BingDictParsedData {
    var parts: [EZTranslatePart] = []
    var exchanges: [EZTranslateExchange] = []
    var simpleWords: [EZTranslateSimpleWord] = []
    var phonetics: [EZWordPhonetic] = []
    var synonyms: [EZTranslatePart] = []
    var antonyms: [EZTranslatePart] = []
    var collocation: [EZTranslatePart] = []
}

// MARK: - Array Safe Subscript

extension Array {
    fileprivate subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
