//
//  EZQueryResult+YoudaoDict.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - EZQueryResult + YoudaoDict

// swiftlint:disable all
extension QueryResult {
    @available(*, deprecated)
    func update(dict model: YoudaoDictResponse) {
        raw = model

        let wordResult = EZTranslateWordResult()
        let language = queryModel.queryFromLanguage

        // Handle English to Chinese translation
        if let ec = model.ec, let word = ec.word?.first {
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
                    if let explanation = tr.tr?.first?.l?.i?.first {
                        let part = EZTranslatePart()
                        var means = explanation

                        let delimiterSymbol = "."
                        let array = explanation.components(separatedBy: delimiterSymbol)
                        if array.count > 1 {
                            let pos = array[0]
                            if pos.count < 5 {
                                part.part = "\(pos)\(delimiterSymbol)"
                                means = array[1].trimmingCharacters(in: .whitespaces)
                            }
                        }
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
        if let ce = model.ce, let word = ce.word?.first {
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
                    if let l = tr.tr?.first?.l {
                        var words: [YoudaoDictResponse.TextWord] = []
                        if let i = l.i {
                            for wordDict in i {
                                switch wordDict {
                                case .string:
                                    break
                                case let .ii(wordDict):
                                    words.append(wordDict)
                                }
                            }
                        }

                        let texts = words.compactMap { $0.text }
                        let text = texts.joined(separator: " ")

                        let simpleWord = EZTranslateSimpleWord()
                        simpleWord.word = text
                        simpleWord.part = l.pos
                        if let tran = l.tran {
                            simpleWord.means = [tran]
                        }
                        simpleWord.showPartMeans = true
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
                    let simpleWord = EZTranslateSimpleWord()
                    simpleWord.word = webTranslation.key

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
