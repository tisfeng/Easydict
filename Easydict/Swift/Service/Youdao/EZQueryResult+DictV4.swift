//
//  EZQueryResult+DictV4.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/8.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - EZQueryResult + DictV4

// swiftlint:disable all
extension EZQueryResult {
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

            if !phonetics.isEmpty {
                wordResult.phonetics = phonetics
            }

            // Parse word translations
            var parts: [EZTranslatePart] = []
            if let trs = word.trs {
                for tr in trs {
                    if let pos = tr.pos,
                       let tran = tr.tran {
                        let part = EZTranslatePart()
                        part.part = pos

                        let means = tran
                        part.means = [means]

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
                    if let text = tr.text,
                       let tran = tr.tran {
                        let simpleWord = EZTranslateSimpleWord()
                        simpleWord.word = text
                        simpleWord.means = [tran]
                        simpleWord.showPartMeans = true
                        simpleWords.append(simpleWord)
                    }
                }
            }

            if !simpleWords.isEmpty {
                wordResult.simpleWords = simpleWords
            }

            if !simpleWords.isEmpty {
                wordResult.simpleWords = simpleWords
            }
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

        // Set word result only if it has parts or simple words
        if wordResult.parts != nil || wordResult.simpleWords != nil {
            self.wordResult = wordResult
        }
    }
}

// swiftlint:enable all
