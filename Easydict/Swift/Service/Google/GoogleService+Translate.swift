//
//  GoogleService+Translate.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

private let kGoogleTranslateURL = "https://translate.google.com"

// MARK: - GoogleService + Translate

extension GoogleService {
    // MARK: - WebApp Translate

    /// This API can get word info, like pronunciation, but transaltion may be inaccurate, compare to web transaltion.
    func webAppTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(result, QueryError(type: .parameter, message: "翻译的文本为空"))
            return
        }

        sendWebAppTranslate(text, from: from, to: to) { [weak self] responseObject, signText, _, error in
            guard let self, let result = result else { return }

            if let error = error {
                completion(result, error)
                return
            }

            if let responseArray = responseObject as? [Any] {
                let googleFromString = responseArray[2] as? String ?? ""
                let googleFrom = languageEnum(fromCode: googleFromString)
                let googleTo = to

                result.raw = responseObject
                result.fromSpeakURL = getAudioURL(
                    withText: text,
                    language: googleFromString,
                    sign: signText ?? ""
                )

                var wordResult: EZTranslateWordResult?

                // 英文查词 中文查词
                if let phoneticArray = responseArray[0] as? [Any],
                   phoneticArray.count > 1,
                   let phonetics = phoneticArray[1] as? [Any],
                   phonetics.count > 3,
                   let phoneticText = phonetics[3] as? String {
                    wordResult = EZTranslateWordResult()

                    let phonetic = EZWordPhonetic()
                    phonetic.name = NSLocalizedString("us_phonetic", comment: "")
                    if EZLanguageManager.shared().isChineseLanguage(from) {
                        phonetic.name = NSLocalizedString("chinese_phonetic", comment: "")
                    }

                    phonetic.value = phoneticText
                    phonetic.speakURL = result.fromSpeakURL
                    phonetic.language = result.queryFromLanguage
                    phonetic.word = text
                    wordResult?.phonetics = [phonetic]
                }

                if let dictResult = responseArray[1] as? [[Any]] {
                    if wordResult == nil {
                        wordResult = EZTranslateWordResult()
                    }

                    if googleFrom == .english,
                       googleTo == .simplifiedChinese || googleTo == .traditionalChinese {
                        // 英文查词
                        var parts: [EZTranslatePart] = []
                        for obj in dictResult {
                            guard obj.count >= 2,
                                  let part = obj[0] as? String,
                                  let meanings = obj[1] as? [Any]
                            else { continue }

                            let partObj = EZTranslatePart()
                            partObj.part = part
                            partObj.means = meanings.compactMap { $0 as? String }
                            if !partObj.means.isEmpty {
                                parts.append(partObj)
                            }
                        }
                        if !parts.isEmpty {
                            wordResult?.parts = parts
                        }
                    } else if googleFrom == .simplifiedChinese
                        || googleFrom == .traditionalChinese, googleTo == .english {
                        // 中文查词
                        var simpleWords: [EZTranslateSimpleWord] = []
                        for obj in dictResult {
                            guard obj.count >= 3,
                                  let part = obj[0] as? String,
                                  let partWords = obj[2] as? [[Any]]
                            else { continue }

                            for wordObj in partWords {
                                guard wordObj.count >= 2,
                                      let wordStr = wordObj[0] as? String,
                                      let means = wordObj[1] as? [Any]
                                else { continue }

                                let simpleWord = EZTranslateSimpleWord()
                                simpleWord.word = wordStr
                                simpleWord.means = means.compactMap { $0 as? String }
                                simpleWord.part = part
                                simpleWords.append(simpleWord)
                            }
                        }
                        if !simpleWords.isEmpty {
                            wordResult?.simpleWords = simpleWords
                        }
                    }
                }

                // Avoid displaying too long phonetic symbols.
                if wordResult?.parts != nil || wordResult?.simpleWords != nil || text.count <= 4 {
                    result.wordResult = wordResult
                }

                // 普通释义
                if let normalArray = responseArray[0] as? [[Any]] {
                    let normalResults = normalArray.compactMap { obj -> String? in
                        guard let first = obj.first as? String else { return nil }
                        return first.trim()
                    }.filter { !$0.isEmpty }

                    if !normalResults.isEmpty {
                        result.translatedResults = normalResults

                        let mergeString =
                            String.combined(
                                components: normalResults,
                                separatedBy: "\n"
                            ) ?? ""
                        let signTo =
                            signFunction.call(withArguments: [mergeString])?.toString() ?? ""
                        result.toSpeakURL = getAudioURL(
                            withText: mergeString,
                            language: languageCode(for: googleTo) ?? "",
                            sign: signTo
                        )
                    }
                }

                if result.wordResult != nil || result.translatedResults != nil {
                    completion(result, nil)
                    return
                }
            }

            gtxTranslate(text, from: from, to: to, completion: completion)
        }
    }

    // MARK: - WebApp Network Request

    func sendWebAppTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (Any?, String?, NSMutableDictionary?, Error?) -> ()
    ) {
        let sign = signFunction.call(withArguments: [text])?.toString() ?? ""

        var url = "\(kGoogleTranslateURL)/translate_a/single"
        url += "?dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t"

        let sourceLangCode = languageCode(for: from) ?? ""
        let targetLangCode = languageCode(for: to) ?? ""

        let params: [String: Any] = [
            "client": "webapp",
            "sl": sourceLangCode,
            "tl": targetLangCode,
            "hl": "en", // zh-CN, en
            "otf": "2",
            "ssel": "3",
            "tsel": "0",
            "kc": "6",
            "tk": sign,
            "q": text,
        ]

        let task = jsonSession.get(
            url,
            parameters: params,
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self = self else { return }
                if queryModel?.isServiceStopped(serviceType().rawValue) == true {
                    return
                }

                if let response = responseObject {
                    completion(response, sign, nil, nil)
                } else {
                    completion(nil, nil, nil, QueryError(type: .api, message: nil))
                }
            },
            failure: { _, error in
                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }
                completion(nil, nil, nil, QueryError(type: .api, message: nil))
            }
        )

        queryModel?.setStop(
            {
                task?.cancel()
            }, serviceType: serviceType().rawValue
        )
    }

    // MARK: - TKK Management

    func sendGetWebAppTKKRequest(completion: @escaping (String?, Error?) -> ()) {
        let url = kGoogleTranslateURL

        htmlSession.get(
            url,
            parameters: nil,
            progress: nil,
            success: { _, responseObject in
                var tkkResult: String?
                if let data = responseObject as? Data,
                   let string = String(data: data, encoding: .utf8) {
                    // tkk:'437961.2280157552'
                    let pattern = "tkk:'\\d+\\.\\d+',"
                    let regex = try? NSRegularExpression(
                        pattern: pattern, options: .caseInsensitive
                    )
                    let matches =
                        regex?.matches(
                            in: string,
                            options: .reportCompletion,
                            range: NSRange(location: 0, length: string.count)
                        ) ?? []

                    for match in matches {
                        let tkk = (string as NSString).substring(with: match.range)
                        if tkk.count > 7 {
                            tkkResult = (tkk as NSString).substring(
                                with: NSRange(location: 5, length: tkk.count - 7)
                            )
                            break
                        }
                    }
                }

                if let tkk = tkkResult, !tkk.isEmpty {
                    completion(tkk, nil)
                } else if let tkk = self.windowObject.objectForKeyedSubscript("TKK").toString(),
                          !tkk.isEmpty {
                    completion(tkk, nil)
                } else {
                    completion(nil, QueryError(type: .api, message: "谷歌翻译获取 tkk 失败"))
                }
            },
            failure: { _, _ in
                completion(nil, QueryError(type: .api, message: "谷歌翻译获取 tkk 失败"))
            }
        )
    }

    func updateWebAppTKK(completion: @escaping (Error?) -> ()) {
        let now = Int64(Date().timeIntervalSince1970) / 3600
        if let tkk = windowObject.objectForKeyedSubscript("TKK").toString(),
           let firstComponent = tkk.components(separatedBy: ".").first,
           let tkkTime = Int64(firstComponent),
           tkkTime == now {
            completion(nil)
            return
        }

        sendGetWebAppTKKRequest { [weak self] tkk, error in
            guard let self = self else { return }
            if let tkk = tkk {
                windowObject.setObject(
                    tkk, forKeyedSubscript: "TKK" as NSCopying & NSObjectProtocol
                )
                completion(nil)
            } else {
                completion(error)
            }
        }
    }

    /// Update the web app TKK value using async/await.
    func updateWebAppTKK() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(), Error>) in
            updateWebAppTKK { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    // MARK: - GTX Translate

    /// GTX can only get translation and src language.
    func sendGTXTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (Any?, String?, NSMutableDictionary?, Error?) -> ()
    ) {
        let sign = signFunction.call(withArguments: [text])?.toString() ?? ""
        let url = "\(kGoogleTranslateURL)/translate_a/single"

        let fromLanguage = languageCode(for: from) ?? ""
        let toLanguage = languageCode(for: to) ?? ""

        let params: [String: Any] = [
            "q": text,
            "sl": fromLanguage,
            "tl": toLanguage,
            "dt": "t",
            "dj": "1",
            "ie": "UTF-8",
            "client": "gtx",
        ]

        let task = jsonSession.get(
            url,
            parameters: params,
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self = self else { return }
                if queryModel?.isServiceStopped(serviceType().rawValue) == true {
                    return
                }

                if let response = responseObject {
                    completion(response, sign, nil, nil)
                } else {
                    completion(nil, nil, nil, QueryError(type: .api, message: nil))
                }
            },
            failure: { _, error in
                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }
                completion(nil, nil, nil, QueryError(type: .api, message: nil))
            }
        )

        queryModel?.setStop(
            {
                task?.cancel()
            }, serviceType: serviceType().rawValue
        )
    }

    // MARK: - GTX Translation Processing

    func gtxTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(result, QueryError(type: .parameter, message: "翻译的文本为空"))
            return
        }

        sendGTXTranslate(text, from: from, to: to) { [weak self] responseObject, signText, _, error in
            guard let self, let result = result else { return }

            if let error = error {
                completion(result, error)
                return
            }

            if let responseDict = responseObject as? [String: Any] {
                let googleFromString = responseDict["src"] as? String ?? ""

                let googleTo = to
                result.fromSpeakURL = getAudioURL(
                    withText: text,
                    language: googleFromString,
                    sign: signText ?? ""
                )

                // 普通释义
                if let sentences = responseDict["sentences"] as? [[String: Any]] {
                    var translationArray: [String] = []

                    // !!!: This Google API has its own paragraph, \n\n , we need to join and convert to text array.
                    for sentenceDict in sentences {
                        if let trans = sentenceDict["trans"] as? String {
                            translationArray.append(trans)
                        }
                    }

                    let translatedText = translationArray.joined()
                    result.translatedResults = translatedText.toParagraphs()

                    let signTo =
                        signFunction.call(withArguments: [translatedText])?.toString() ?? ""
                    result.toSpeakURL = getAudioURL(
                        withText: translatedText,
                        language: languageCode(for: googleTo) ?? "",
                        sign: signTo
                    )
                }

                if result.wordResult != nil || result.translatedResults != nil {
                    completion(result, nil)
                    return
                }
            }
            completion(result, QueryError(type: .api, message: nil))
        }
    }

    // MARK: - Language Detection

    func gtxDetect(
        _ text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(.auto, QueryError(type: .parameter, message: "识别语言的文本为空"))
            return
        }

        // 截取一部分识别语言就行
        let queryString = (text as NSString).trimmingToMaxLength(73)

        sendGTXTranslate(queryString, from: .auto, to: .auto) { responseObject, _, _, error in
            if let error = error {
                completion(.auto, error)
                return
            }

            if let responseDict = responseObject as? [String: Any],
               let googleFromString = responseDict["src"] as? String {
                let googleFrom = self.languageEnum(fromCode: googleFromString)

                if googleFrom != .auto {
                    completion(googleFrom, nil)
                    return
                }
            }
            completion(.auto, QueryError(type: .api, message: "识别语言失败"))
        }
    }

    func webAppDetect(
        _ text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(.auto, QueryError(type: .parameter, message: "识别语言的文本为空"))
            return
        }

        // 截取一部分识别语言就行
        let queryString = (text as NSString).trimmingToMaxLength(73)

        sendWebAppTranslate(queryString, from: .auto, to: .auto) { responseObject, _, _, error in
            if let error = error {
                completion(.auto, error)
                return
            }

            if let responseArray = responseObject as? [Any],
               responseArray.count > 2,
               let googleFromString = responseArray[2] as? String {
                let googleFromLanguage = self.languageEnum(fromCode: googleFromString)

                /**
                 Sometimes, scr is different from extended_srclangs, such as "開門 ": src = "zh-CN", extended_srclangs = "zh-TW"
                 */
                if responseArray.count > 8,
                   let languageArray = responseArray[8] as? [Any],
                   let languages = languageArray.last as? [Any],
                   let language = languages.first as? String {
                    logInfo("Google detect language: \(language)")
                    if let lang = self.language(fromCode: language), lang != .auto {
                        completion(lang, nil)
                        return
                    }
                }
                completion(googleFromLanguage, nil)
                return
            }
            completion(.auto, QueryError(type: .api, message: "识别语言失败"))
        }
    }
}
