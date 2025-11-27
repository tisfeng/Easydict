//
//  GoogleService.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/27.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import Foundation
import JavaScriptCore

private let kGoogleTranslateURL = "https://translate.google.com"

// MARK: - GoogleService

@objc(EZGoogleTranslate)
class GoogleService: QueryService {
    // MARK: Lifecycle

    override init() {
        super.init()
    }

    // MARK: Internal

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        let processedText = maxTextLength(text, fromLanguage: from)

        // TODO: We should the Google web translate API instead.
        // Two APIs are hard to maintain, and they may differ with web translation.
        let queryDictionary = processedText.shouldQueryDictionary(
            withLanguage: from,
            maxWordCount: 1
        )
        if queryDictionary {
            // This API can get word info, like pronunciation.
            webAppTranslate(processedText, from: from, to: to, completion: completion)
        } else {
            gtxTranslate(processedText, from: from, to: to, completion: completion)
        }
    }

    override func serviceType() -> ServiceType {
        .google
    }

    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary, .sentence, .translation]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func name() -> String {
        NSLocalizedString("google_translate", comment: "")
    }

    override func link() -> String {
        kGoogleTranslateURL
    }

    override func wordLink(_ queryModel: EZQueryModel) -> String? {
        guard let from = languageCode(for: queryModel.queryFromLanguage),
              let to = languageCode(for: queryModel.queryTargetLanguage)
        else { return nil }

        let maxText = maxTextLength(
            queryModel.queryText,
            fromLanguage: queryModel.queryFromLanguage
        )
        let text = maxText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        return "\(kGoogleTranslateURL)/?sl=\(from)&tl=\(to)&text=\(text)&op=translate"
    }

    /// Google translate support languages: https://cloud.google.com/translate/docs/languages?hl=zh-cn
    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let languages: [Any] = [
            Language.auto, "auto",
            Language.simplifiedChinese, "zh-CN",
            Language.traditionalChinese, "zh-TW",
            Language.english, "en",
            Language.japanese, "ja",
            Language.korean, "ko",
            Language.french, "fr",
            Language.spanish, "es",
            Language.portuguese, "pt-PT",
            Language.brazilianPortuguese, "pt",
            Language.italian, "it",
            Language.german, "de",
            Language.russian, "ru",
            Language.arabic, "ar",
            Language.swedish, "sv",
            Language.romanian, "ro",
            Language.thai, "th",
            Language.slovak, "sk",
            Language.dutch, "nl",
            Language.hungarian, "hu",
            Language.greek, "el",
            Language.danish, "da",
            Language.finnish, "fi",
            Language.polish, "pl",
            Language.czech, "cs",
            Language.turkish, "tr",
            Language.lithuanian, "lt",
            Language.latvian, "lv",
            Language.ukrainian, "uk",
            Language.bulgarian, "bg",
            Language.indonesian, "id",
            Language.malay, "ms",
            Language.slovenian, "sl",
            Language.estonian, "et",
            Language.vietnamese, "vi",
            Language.persian, "fa",
            Language.hindi, "hi",
            Language.telugu, "te",
            Language.tamil, "ta",
            Language.urdu, "ur",
            Language.filipino, "tl",
            Language.khmer, "km",
            Language.lao, "lo",
            Language.bengali, "bn",
            Language.burmese, "my",
            Language.norwegian, "no",
            Language.serbian, "sr",
            Language.croatian, "hr",
            Language.mongolian, "mn",
            Language.hebrew, "iw",
            Language.georgian, "ka",
            NSNull(),
        ]

        let orderedDict = MMOrderedDictionary()
        for i in stride(from: 0, to: languages.count - 1, by: 2) {
            if let key = languages[i] as? NSObject,
               let value = languages[i + 1] as? NSObject {
                orderedDict.setObject(value, forKey: key)
            }
        }
        return orderedDict
    }

    override func detectText(
        _ text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        webAppDetect(text, completion: completion)
    }

    override func text(
        toAudio text: String,
        fromLanguage: Language,
        accent: String?,
        completion: @escaping (String?, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(
                nil,
                QueryError(type: .parameter, message: "获取音频的文本为空")
            )
            return
        }

        // TODO: need to optimize, Ref: https://github.com/florabtw/google-translate-tts/blob/master/src/synthesize.js

        if fromLanguage == .auto {
            detectText(text) { [weak self] (lang: Language, error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    completion(nil, error)
                    return
                }

                let sign = signFunction.call(withArguments: [text])?.toString() ?? ""
                let url = getAudioURL(
                    withText: text,
                    language: getTTSLanguageCode(lang, accent: accent),
                    sign: sign
                )
                completion(url, nil)
            }
        } else {
            updateWebAppTKK { error in
                if let error = error {
                    completion(nil, error)
                    return
                }

                let sign = self.signFunction.call(withArguments: [text])?.toString() ?? ""
                let url = self.getAudioURL(
                    withText: text,
                    language: self.getTTSLanguageCode(fromLanguage, accent: accent),
                    sign: sign
                )
                completion(url, nil)
            }
        }
    }

    internal override func languageEnum(fromCode code: String) -> Language {
        language(fromCode: code) ?? .auto
    }

    internal override func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        // TODO: Implement accent handling
        languageCode(for: language) ?? "en"
    }

    // MARK: Private

    private lazy var jsContext: JSContext = {
        let context = JSContext()
        if let jsPath = Bundle.main.path(forResource: "google-translate-sign", ofType: "js"),
           let jsString = try? String(contentsOfFile: jsPath, encoding: .utf8) {
            context?.evaluateScript(jsString)
        }
        return context!
    }()

    private lazy var signFunction: JSValue = {
        jsContext.objectForKeyedSubscript("sign")
    }()

    private lazy var windowObject: JSValue = {
        jsContext.objectForKeyedSubscript("window")
    }()

    private lazy var htmlSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()

        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        session.requestSerializer = requestSerializer

        let responseSerializer = AFHTTPResponseSerializer()
        responseSerializer.acceptableContentTypes = ["text/html"]
        session.responseSerializer = responseSerializer

        return session
    }()

    private lazy var jsonSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()

        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.120 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        session.requestSerializer = requestSerializer

        let responseSerializer = AFJSONResponseSerializer()
        responseSerializer.acceptableContentTypes = ["application/json"]
        session.responseSerializer = responseSerializer

        return session
    }()

    private func getAudioURL(withText text: String, language: String, sign: String) -> String {
        // TODO: text length must <= 200, maybe we can split it.
        let processedText = (text as NSString).trimmingToMaxLength(200)

        return
            "\(kGoogleTranslateURL)/translate_tts?ie=UTF-8&q=\(processedText.encode)&tl=\(language)&total=1&idx=0&textlen=\(processedText.count)&tk=\(sign)&client=webapp&prev=input"
    }

    // MARK: - WebApp, including word info

    /// This API can get word info, like pronunciation, but transaltion may be inaccurate, compare to web transaltion.
    private func webAppTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(result, QueryError(type: .parameter, message: "翻译的文本为空"))
            return
        }

        sendWebAppTranslate(text, from: from, to: to) {
            [weak self] responseObject, signText, _, error in
            guard let self = self else { return }
            let result = result
            if let error = error {
                completion(result, error)
                return
            }

            var message: String?
            if let responseArray = responseObject as? [Any] {
                do {
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
                            let parts = NSMutableArray()
                            for obj in dictResult {
                                guard obj.count >= 2,
                                      let part = obj[0] as? String,
                                      let meanings = obj[1] as? [Any]
                                else { continue }

                                let partObj = EZTranslatePart()
                                partObj.part = part
                                partObj.means = meanings.compactMap { $0 as? String }
                                if !partObj.means.isEmpty {
                                    parts.add(partObj)
                                }
                            }
                            if !parts.isEmpty {
                                wordResult?.parts = parts as! [EZTranslatePart]
                            }
                        } else if googleFrom == .simplifiedChinese
                            || googleFrom == .traditionalChinese, googleTo == .english {
                            // 中文查词
                            let simpleWords = NSMutableArray()
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
                                    simpleWords.add(simpleWord)
                                }
                            }
                            if !simpleWords.isEmpty {
                                wordResult?.simpleWords =
                                    simpleWords as [AnyObject] as! [EZTranslateSimpleWord]
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
                            guard let arr = obj as? [Any],
                                  let first = arr.first as? String
                            else { return nil }
                            return first.trim()
                        }.filter { !$0.isEmpty }

                        if !normalResults.isEmpty {
                            result.translatedResults = normalResults as [AnyObject] as! [String]

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

                } catch {
                    logError("谷歌翻译接口数据解析异常 \(error)")
                    message = "谷歌翻译接口数据解析异常"
                }
            }

            gtxTranslate(text, from: from, to: to, completion: completion)
        }
    }

    private func sendWebAppTranslate(
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
                if queryModel.isServiceStopped(serviceType().rawValue) {
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

        queryModel.setStop(
            {
                task?.cancel()
            }, serviceType: serviceType().rawValue
        )
    }

    private func sendGetWebAppTKKRequest(completion: @escaping (String?, Error?) -> ()) {
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

    private func updateWebAppTKK(completion: @escaping (Error?) -> ()) {
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

    // MARK: - GTX Transalte, the same as web translation

    /// GTX can only get translation and src language.
    private func sendGTXTranslate(
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
                if queryModel.isServiceStopped(serviceType().rawValue) {
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

        queryModel.setStop(
            {
                task?.cancel()
            }, serviceType: serviceType().rawValue
        )
    }

    private func gtxTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(result, QueryError(type: .parameter, message: "翻译的文本为空"))
            return
        }

        sendGTXTranslate(text, from: from, to: to) {
            [weak self] responseObject, signText, _, error in
            guard let self = self else { return }
            let result = result
            if let error = error {
                completion(result, error)
                return
            }

            var message: String?
            if let responseDict = responseObject as? [String: Any] {
                do {
                    let googleFromString = responseDict["src"] as? String ?? ""
                    var googleFrom = languageEnum(fromCode: googleFromString)

                    // Sometimes, scr is different from extended_srclangs, such as "開門 ": src = "zh-CN", extended_srclangs = "zh-TW"
                    if let extendedSrclangs = responseDict["ld_result"] as? [String: Any],
                       let languages = extendedSrclangs["extended_srclangs"] as? [String],
                       let languageStr = languages.first,
                       let detectedLang = language(fromCode: languageStr),
                       detectedLang != .auto {
                        googleFrom = detectedLang
                    }

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

                } catch {
                    logError("谷歌翻译接口数据解析异常 \(error)")
                    message = "谷歌翻译接口数据解析异常"
                }
            }
            completion(result, QueryError(type: .api, message: message))
        }
    }

    private func gtxDetect(
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

            var message: String?
            if let responseDict = responseObject as? [String: Any],
               let googleFromString = responseDict["src"] as? String {
                var googleFrom = self.languageEnum(fromCode: googleFromString)

                if googleFrom != .auto {
                    completion(googleFrom, nil)
                    return
                }
            }
            completion(.auto, QueryError(type: .api, message: message ?? "识别语言失败"))
        }
    }

    private func webAppDetect(
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

            var message: String?
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
            completion(.auto, QueryError(type: .api, message: message ?? "识别语言失败"))
        }
    }

    // MARK: - Helper Methods

    /// Get max text length for Google Translate.
    private func maxTextLength(_ text: String, fromLanguage: Language) -> String {
        // Chinese max text length 1800
        // English max text length 5000
        if EZLanguageManager.shared().isChineseLanguage(fromLanguage), text.count > 1800 {
            return String(text.prefix(1800))
        } else {
            return (text as NSString).trimmingToMaxLength(5000)
        }
    }

    private func languageCode(for language: Language) -> String? {
        switch language {
        case .auto: return "auto"
        case .simplifiedChinese: return "zh-CN"
        case .traditionalChinese: return "zh-TW"
        case .english: return "en"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .french: return "fr"
        case .spanish: return "es"
        case .portuguese: return "pt-PT"
        case .brazilianPortuguese: return "pt"
        case .italian: return "it"
        case .german: return "de"
        case .russian: return "ru"
        case .arabic: return "ar"
        case .swedish: return "sv"
        case .romanian: return "ro"
        case .thai: return "th"
        case .slovak: return "sk"
        case .dutch: return "nl"
        case .hungarian: return "hu"
        case .greek: return "el"
        case .danish: return "da"
        case .finnish: return "fi"
        case .polish: return "pl"
        case .czech: return "cs"
        case .turkish: return "tr"
        case .lithuanian: return "lt"
        case .latvian: return "lv"
        case .ukrainian: return "uk"
        case .bulgarian: return "bg"
        case .indonesian: return "id"
        case .malay: return "ms"
        case .slovenian: return "sl"
        case .estonian: return "et"
        case .vietnamese: return "vi"
        case .persian: return "fa"
        case .hindi: return "hi"
        case .telugu: return "te"
        case .tamil: return "ta"
        case .urdu: return "ur"
        case .filipino: return "tl"
        case .khmer: return "km"
        case .lao: return "lo"
        case .bengali: return "bn"
        case .burmese: return "my"
        case .norwegian: return "no"
        case .serbian: return "sr"
        case .croatian: return "hr"
        case .mongolian: return "mn"
        case .hebrew: return "iw"
        case .georgian: return "ka"
        default: return nil
        }
    }

    private func language(fromCode code: String) -> Language? {
        switch code {
        case "auto": return .auto
        case "zh-CN": return .simplifiedChinese
        case "zh-TW": return .traditionalChinese
        case "en": return .english
        case "ja": return .japanese
        case "ko": return .korean
        case "fr": return .french
        case "es": return .spanish
        case "pt-PT": return .portuguese
        case "pt": return .brazilianPortuguese
        case "it": return .italian
        case "de": return .german
        case "ru": return .russian
        case "ar": return .arabic
        case "sv": return .swedish
        case "ro": return .romanian
        case "th": return .thai
        case "sk": return .slovak
        case "nl": return .dutch
        case "hu": return .hungarian
        case "el": return .greek
        case "da": return .danish
        case "fi": return .finnish
        case "pl": return .polish
        case "cs": return .czech
        case "tr": return .turkish
        case "lt": return .lithuanian
        case "lv": return .latvian
        case "uk": return .ukrainian
        case "bg": return .bulgarian
        case "id": return .indonesian
        case "ms": return .malay
        case "sl": return .slovenian
        case "et": return .estonian
        case "vi": return .vietnamese
        case "fa": return .persian
        case "hi": return .hindi
        case "te": return .telugu
        case "ta": return .tamil
        case "ur": return .urdu
        case "tl": return .filipino
        case "km": return .khmer
        case "lo": return .lao
        case "bn": return .bengali
        case "my": return .burmese
        case "no": return .norwegian
        case "sr": return .serbian
        case "hr": return .croatian
        case "mn": return .mongolian
        case "iw": return .hebrew
        case "ka": return .georgian
        default: return nil
        }
    }
}

// MARK: - Error Helper

// private func QueryError(_ type: EZQueryErrorType, message: String?) -> NSError {
//    EZQueryError.error(with: type, message: message ?? "")
// }
