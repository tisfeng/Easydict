//
//  EZQueryResult+DictV4.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/8.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - EZQueryResult + DictV4

// swiftlint:disable all
extension QueryResult {
    func update(dictV4 model: YoudaoDictResponseV4) {
        raw = model

        let wordResult = EZTranslateWordResult()
        let language = queryModel.queryFromLanguage

        // Handle English to Chinese translation
        if let ec = model.ec, let word = ec.word {
            // Parse phonetics
            var phonetics: [EZWordPhonetic] = []
            let audioURL = "https://dict.youdao.com/dictvoice?audio="

            // US phonetic
            if let usphone = word.usphone {
                let phonetic = EZWordPhonetic()
                phonetic.name = NSLocalizedString("us_phonetic", comment: "")
                phonetic.language = language
                phonetic.accent = "us"
                phonetic.word = queryText
                phonetic.value = usphone
                if let usspeech = word.usspeech {
                    let speechURL = "\(audioURL)\(usspeech)"
                    phonetic.speakURL = speechURL
                    fromSpeakURL = speechURL
                    queryModel.audioURL = speechURL
                }
                phonetics.append(phonetic)
            }

            // UK phonetic
            if let ukphone = word.ukphone {
                let phonetic = EZWordPhonetic()
                phonetic.name = NSLocalizedString("uk_phonetic", comment: "")
                phonetic.language = language
                phonetic.accent = "uk"
                phonetic.word = queryText
                phonetic.value = ukphone
                if let ukspeech = word.ukspeech {
                    phonetic.speakURL = "\(audioURL)\(ukspeech)"
                }
                phonetics.append(phonetic)
            }

            // Rare words and proper nouns (e.g. "Pontryagin") come back
            // without usphone/ukphone even though Youdao TTS can pronounce
            // them; synthesize a speaker-only entry so a word lookup always
            // offers a pronunciation.
            if phonetics.isEmpty {
                let phonetic = EZWordPhonetic()
                // The phonetic row is laid out around the name label, so an
                // empty name collapses the row under the 23pt audio button.
                phonetic.name = NSLocalizedString("us_phonetic", comment: "")
                phonetic.language = language
                phonetic.word = queryText
                phonetic.accent = "us"
                // `queryItems` percent-encodes `&` and `=` in values, so words
                // such as "rock & roll" stay a single `audio` value. It leaves
                // `+` as is, which servers read as a space, so escape it too.
                // `type=2` selects the US voice.
                var components = URLComponents(string: audioURL)
                components?.queryItems = [
                    URLQueryItem(name: "audio", value: queryText),
                    URLQueryItem(name: "type", value: "2"),
                ]
                if let query = components?.percentEncodedQuery {
                    components?.percentEncodedQuery = query
                        .replacingOccurrences(of: "+", with: "%2B")
                }
                if let speechURL = components?.url?.absoluteString {
                    phonetic.speakURL = speechURL
                    fromSpeakURL = speechURL
                    queryModel.audioURL = speechURL
                    phonetics.append(phonetic)
                }
            }
            wordResult.phonetics = phonetics

            // Parse word translations
            var parts: [EZTranslatePart] = []
            if let trs = word.trs {
                for tr in trs {
                    let part = EZTranslatePart()
                    part.part = tr.pos ?? ""

                    var means: [String] = .init()
                    if let tran = tr.tran {
                        means.append(tran)
                    }
                    part.means = means
                    if !means.isEmpty {
                        parts.append(part)
                    }
                }
            }

            if !parts.isEmpty {
                wordResult.parts = parts
            }

            // Parse word forms
            if let wfs = word.wfs {
                var exchanges: [EZTranslateExchange] = []
                for element in wfs {
                    let exchange = EZTranslateExchange()
                    if let wf = element.wf {
                        exchange.name = wf.name ?? ""
                        exchange.words = wf.value?.components(separatedBy: "或") ?? []
                    }
                    exchanges.append(exchange)
                }
                if !exchanges.isEmpty {
                    wordResult.exchanges = exchanges
                }
            }

            wordResult.tags = ec.examType
        }

        // Handle Chinese to English translation
        if let ce = model.ce, let word = ce.word {
            // Parse phonetics
            var phonetics: [EZWordPhonetic] = []
            if let phone = word.phone {
                let phonetic = EZWordPhonetic()
                phonetic.word = queryText
                phonetic.language = language
                phonetic.name = NSLocalizedString("chinese_phonetic", comment: "")
                phonetic.value = phone
                phonetics.append(phonetic)
            }

            if !phonetics.isEmpty {
                wordResult.phonetics = phonetics
            }

            // Parse word translations
            var simpleWords: [EZTranslateSimpleWord] = []
            if let trs = word.trs {
                for tr in trs {
                    let simpleWord = EZTranslateSimpleWord()
                    simpleWord.word = tr.text ?? ""

                    var means: [String] = .init()
                    if let tran = tr.tran {
                        means.append(tran)
                    }
                    simpleWord.means = means
                    simpleWord.showPartMeans = true

                    if !simpleWord.word.isEmpty || !means.isEmpty {
                        simpleWords.append(simpleWord)
                    }
                }
            }
            wordResult.simpleWords = simpleWords
        }

        // Handle web translations
        if let webTrans = model.webTrans {
            var webExplanations: [EZTranslateSimpleWord] = []
            if let webTranslations = webTrans.webTranslation {
                for webTranslation in webTranslations {
                    guard let key = webTranslation.key else {
                        continue
                    }
                    let simpleWord = EZTranslateSimpleWord()
                    simpleWord.word = key

                    let explanations = webTranslation.trans?.compactMap { $0.value }
                    simpleWord.means = explanations
                    webExplanations.append(simpleWord)
                }
            }

            if !webExplanations.isEmpty {
                var simpleWords = wordResult.simpleWords ?? []
                simpleWords.append(contentsOf: webExplanations)
                wordResult.simpleWords = simpleWords
            }
        }

        // fanyi
        if let fanyi = model.fanyi, let translation = fanyi.tran {
            translatedResults = [translation]
        }

        updateCollinsAndExamples(dictV4: model, wordResult: wordResult)

        // Set word result only if it has parts or simple words
        if wordResult.parts != nil || wordResult.simpleWords != nil {
            self.wordResult = wordResult
        }
    }
}

// swiftlint:enable all

// MARK: - Collins and example sentences

extension QueryResult {
    /// At most this many Collins senses and example sentences are shown, to keep the card short.
    static let maxCollinsSenses = 3
    static let maxExampleSentences = 3

    /// Splits a Collins `tran` such as `If something declines, it becomes less…. 下降`
    /// into the English definition and the trailing Chinese gloss, if any.
    static func splitCollinsTranslation(_ text: String) -> (definition: String, meaning: String?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"\s([^A-Za-z<>]*\p{Han}[^A-Za-z<>]*)$"#
        guard let range = trimmed.range(of: pattern, options: .regularExpression) else {
            return (trimmed, nil)
        }
        let meaning = trimmed[range].trimmingCharacters(in: .whitespacesAndNewlines)
        let definition = trimmed[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
        return (definition, meaning.isEmpty ? nil : meaning)
    }

    /// Fills the Collins senses and bilingual examples that the word detail response already carries.
    func updateCollinsAndExamples(dictV4 model: YoudaoDictResponseV4, wordResult: EZTranslateWordResult) {
        if Defaults[.youdaoShowCollins], let entries = model.collins?.collinsEntries {
            var senses: [EZCollinsSense] = []
            for entry in entries {
                for item in entry.entries?.entry ?? [] {
                    for tran in item.tranEntry ?? [] {
                        guard senses.count < Self.maxCollinsSenses,
                              let text = tran.tran, !text.isEmpty
                        else { continue }
                        let parts = Self.splitCollinsTranslation(text)
                        let sense = EZCollinsSense()
                        sense.partOfSpeech = tran.posEntry?.pos
                        sense.register = tran.register?.value
                        sense.meaning = parts.meaning
                        sense.definition = parts.definition
                        // One example per sense keeps three senses readable at a glance.
                        if let example = tran.examSents?.sent?.first(where: { $0.engSent?.isEmpty == false }),
                           let english = example.engSent {
                            sense.examples = [EZExampleSentence(text: english, translation: example.chnSent)]
                        }
                        senses.append(sense)
                    }
                }
                if wordResult.collinsStar == 0, let star = entry.star.flatMap(Int.init) {
                    wordResult.collinsStar = star
                }
            }
            if !senses.isEmpty {
                wordResult.collinsSenses = senses
            }
        }

        if Defaults[.youdaoShowExampleSentences], let pairs = model.blngSentsPart?.sentencePair {
            let examples = pairs.prefix(Self.maxExampleSentences).compactMap { pair -> EZExampleSentence? in
                guard let text = pair.sentenceEng ?? pair.sentence, !text.isEmpty else { return nil }
                return EZExampleSentence(text: text, translation: pair.sentenceTranslation)
            }
            if !examples.isEmpty {
                wordResult.exampleSentences = examples
            }
        }
    }
}
