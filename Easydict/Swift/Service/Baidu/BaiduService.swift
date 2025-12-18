//
//  BaiduService.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import AppKit
import Foundation
import JavaScriptCore

private let kBaiduTranslateURL = "https://fanyi.baidu.com"

// MARK: - BaiduService

@objc(EZBaiduTranslate)
@objcMembers
final class BaiduService: QueryService {
    // MARK: Internal

    // MARK: - Overrides

    override func resultDidUpdate(_ result: EZQueryResult) {
        super.resultDidUpdate(result)
        apiTranslate.result = result
    }

    override func serviceType() -> ServiceType {
        .baidu
    }

    override func supportedQueryType() -> EZQueryTextType {
        let defaultType: EZQueryTextType = [.dictionary, .sentence, .translation]
        let configured = Configuration.shared.queryTextTypeForServiceType(serviceType())
        return configured.isEmpty ? defaultType : configured
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func name() -> String {
        NSLocalizedString("baidu_translate", comment: "")
    }

    override func link() -> String {
        kBaiduTranslateURL
    }

    override func wordLink(_ queryModel: EZQueryModel) -> String? {
        guard let from = languageCode(forLanguage: queryModel.queryFromLanguage),
              let to = languageCode(forLanguage: queryModel.queryTargetLanguage) else {
            return nil
        }

        let encodedText = queryModel.queryText.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? ""
        return "\(kBaiduTranslateURL)/#\(from)/\(to)/\(encodedText)"
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let orderedDict = MMOrderedDictionary()
        let items: [Any] = [
            Language.auto, "auto",
            Language.simplifiedChinese, "zh",
            Language.classicalChinese, "wyw",
            Language.traditionalChinese, "cht",
            Language.english, "en",
            Language.japanese, "jp",
            Language.korean, "kor",
            Language.french, "fra",
            Language.spanish, "spa",
            Language.portuguese, "pt",
            Language.brazilianPortuguese, "pot",
            Language.italian, "it",
            Language.german, "de",
            Language.russian, "ru",
            Language.arabic, "ara",
            Language.swedish, "swe",
            Language.romanian, "rom",
            Language.thai, "th",
            Language.slovak, "slo",
            Language.dutch, "nl",
            Language.hungarian, "hu",
            Language.greek, "el",
            Language.danish, "dan",
            Language.finnish, "fin",
            Language.polish, "pl",
            Language.czech, "cs",
            Language.turkish, "tr",
            Language.lithuanian, "lit",
            Language.latvian, "lav",
            Language.ukrainian, "ukr",
            Language.bulgarian, "bul",
            Language.indonesian, "id",
            Language.malay, "msa",
            Language.slovenian, "slv",
            Language.estonian, "est",
            Language.vietnamese, "vie",
            Language.persian, "per",
            Language.hindi, "hin",
            Language.telugu, "tel",
            Language.tamil, "tam",
            Language.urdu, "urd",
            Language.filipino, "fil",
            Language.khmer, "khm",
            Language.lao, "lo",
            Language.bengali, "ben",
            Language.burmese, "bur",
            Language.norwegian, "nor",
            Language.serbian, "srp",
            Language.croatian, "hrv",
            Language.mongolian, "mon",
            Language.hebrew, "heb",
            Language.georgian, "geo",
        ]

        for index in stride(from: 0, to: items.count, by: 2) {
            let key = items[index]
            if index + 1 < items.count {
                let value = items[index + 1]
                if let key = key as? NSCopying {
                    orderedDict.setObject(value, forKey: key)
                }
            }
        }

        return orderedDict
    }

    override func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(result, QueryError.error(type: .parameter, message: "翻译的文本为空"))
            return
        }

        let trimmedText = (text as NSString).ns_trimToMaxLength(5000) as String
        updateCookieAndToken()

        if apiTranslate.isEnable {
            apiTranslate.result = result
            let fromCode = Language(rawValue: languageCode(forLanguage: from) ?? "") ?? from
            let toCode = Language(rawValue: languageCode(forLanguage: to) ?? "") ?? to

            apiTranslate.translate(trimmedText, from: fromCode, to: toCode) { [weak self] result, error in
                guard let self else { return }
                completion(result ?? self.result, error)
            }
            return
        }

        let performRequest: () -> () = { [weak self] in
            guard let self else { return }

            let translateBlock: (Language) -> () = { [weak self] detectedFrom in
                guard let self else { return }
                sendTranslateRequest(trimmedText, from: detectedFrom, to: to, completion: completion)
            }

            if from == .auto {
                detectText(trimmedText) { [weak self] detectedLanguage, error in
                    guard let self else { return }
                    if let error {
                        completion(result, error)
                        return
                    }
                    translateBlock(detectedLanguage)
                }
            } else {
                translateBlock(from)
            }
        }

        if token == nil || gtk == nil {
            sendGetTokenAndGtkRequest { [weak self] token, gtk, error in
                guard let self else { return }
                if let error {
                    completion(result, error)
                    return
                }

                guard let token, let gtk else {
                    completion(result, QueryError.error(type: .api, message: "Get token failed."))
                    return
                }

                self.token = token
                self.gtk = gtk
                performRequest()
            }
        } else {
            performRequest()
        }
    }

    override func detectText(
        _ text: String,
        completion: @escaping (Language, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(.auto, QueryError.error(type: .parameter, message: "识别语言的文本为空"))
            return
        }

        let queryString = (text as NSString).ns_trimToMaxLength(73) as String
        let url = "\(kBaiduTranslateURL)/langdetect"

        jsonSession.post(
            url,
            parameters: ["query": queryString],
            constructingBodyWith: nil,
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self else { return }
                if let json = responseObject as? [String: Any] {
                    if let from = json["lan"] as? String, !from.isEmpty {
                        completion(languageEnum(fromCode: from), nil)
                    } else {
                        completion(.auto, QueryError.error(type: .unsupportedLanguage))
                    }
                    return
                }
                completion(.auto, QueryError.error(type: .api, message: "判断语言失败"))
            },
            failure: { _, _ in
                completion(.auto, QueryError.error(type: .api, message: "判断语言失败"))
            }
        )
    }

    override func textToAudio(
        _ text: String,
        fromLanguage: Language,
        accent: String?,
        completion: @escaping (String?, Error?) -> ()
    ) {
        guard !text.isEmpty else {
            completion(nil, QueryError.error(type: .parameter, message: "获取音频的文本为空"))
            return
        }

        if fromLanguage == .auto {
            detectText(text) { [weak self] detectedLanguage, error in
                guard let self else { return }
                if let error {
                    completion(nil, error)
                } else {
                    let url = getAudioURL(with: text, langCode: getTTSLanguageCode(detectedLanguage, accent: accent))
                    completion(url, nil)
                }
            }
        } else {
            let url = getAudioURL(with: text, langCode: getTTSLanguageCode(fromLanguage, accent: accent))
            completion(url, nil)
        }
    }

    override func getTTSLanguageCode(_ language: Language, accent: String?) -> String {
        if language == .english {
            return accent == "uk" ? "uk" : "en"
        }
        return super.getTTSLanguageCode(language, accent: accent)
    }

    override func ocr(
        _ image: NSImage,
        from: Language,
        to: Language,
        completion: @escaping (EZOCRResult?, Error?) -> ()
    ) {
        guard let data = image.mm_PNGData else {
            completion(nil, QueryError.error(type: .parameter, message: "图片为空"))
            return
        }

        let fromLang = from == .auto ? languageCode(forLanguage: .english) : languageCode(forLanguage: from)
        let toLang: String?
        if to == .auto {
            let target = EZLanguageManager.shared().userTargetLanguage(withSourceLanguage: from)
            toLang = languageCode(forLanguage: target)
        } else {
            toLang = languageCode(forLanguage: to)
        }

        let url = "\(kBaiduTranslateURL)/getocr"
        let params: [String: Any] = [
            "image": data,
            "from": fromLang ?? "",
            "to": toLang ?? "",
        ]

        jsonSession.post(
            url,
            parameters: params,
            constructingBodyWith: { formData in
                formData.appendPart(withFileData: data, name: "image", fileName: "blob", mimeType: "image/png")
            },
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self else { return }
                guard let json = responseObject as? [String: Any],
                      let data = json["data"] as? [String: Any]
                else {
                    completion(nil, QueryError.error(type: .api, message: "识别图片文本失败"))
                    return
                }

                let ocrResult = EZOCRResult()
                if let from = data["from"] as? String {
                    ocrResult.from = languageEnum(fromCode: from)
                }
                if let to = data["to"] as? String {
                    ocrResult.to = languageEnum(fromCode: to)
                }
                if let src = data["src"] as? [String] {
                    let filtered = src.filter { !$0.isEmpty }
                    if !filtered.isEmpty {
                        let ocrTexts = filtered.map { text -> EZOCRText in
                            let ocrText = EZOCRText()
                            ocrText.text = text
                            return ocrText
                        }
                        ocrResult.ocrTextArray = ocrTexts
                        ocrResult.texts = filtered
                    }
                }
                ocrResult.raw = responseObject

                let texts = ocrResult.texts
                if !texts.isEmpty {
                    let merged = texts.joined(separator: " ")
                    ocrResult.mergedText = merged
                    completion(ocrResult, nil)
                    return
                }

                completion(nil, QueryError.error(type: .api, message: "识别图片文本失败"))
            },
            failure: { _, _ in
                completion(nil, QueryError.error(type: .api, message: "识别图片文本失败"))
            }
        )
    }

    override func ocrAndTranslate(
        _ image: NSImage,
        from: Language,
        to: Language,
        ocrSuccess: @escaping (EZOCRResult, Bool) -> (),
        completion: @escaping (EZOCRResult?, EZQueryResult?, Error?) -> ()
    ) {
        ocr(image, from: from, to: to) { [weak self] ocrResult, error in
            guard let self else { return }
            guard let ocrResult else {
                completion(nil, nil, error)
                return
            }

            ocrSuccess(ocrResult, true)
            translate(ocrResult.mergedText, from: from, to: to) { result, error in
                completion(ocrResult, result, error)
            }
        }
    }

    // MARK: Private

    // MARK: - Private properties

    private lazy var jsContext: JSContext = {
        let context = JSContext()
        if let jsPath = Bundle.main.path(forResource: "baidu-translate-sign", ofType: "js"),
           let jsString = try? String(contentsOfFile: jsPath, encoding: .utf8) {
            context?.evaluateScript(jsString)
        }
        return context!
    }()

    private lazy var jsFunction: JSValue = {
        jsContext.objectForKeyedSubscript("encrypt")
    }()

    private lazy var htmlSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        session.requestSerializer = AFHTTPRequestSerializer()
        let responseSerializer = AFHTTPResponseSerializer()
        responseSerializer.acceptableContentTypes = ["text/html"]
        session.responseSerializer = responseSerializer
        return session
    }()

    private lazy var jsonSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        session.requestSerializer = AFHTTPRequestSerializer()
        let responseSerializer = AFJSONResponseSerializer()
        responseSerializer.acceptableContentTypes = ["application/json"]
        session.responseSerializer = responseSerializer
        return session
    }()

    private lazy var apiTranslate: BaiduApiTranslate = {
        BaiduApiTranslate(queryModel: queryModel ?? EZQueryModel())
    }()

    private var token: String?
    private var gtk: String?
    private var error997Count = 0

    private var cookie: String {
        var storedCookie = UserDefaults.standard.string(forKey: kBaiduTranslateURL)
            ?? "BAIDUID=0F8E1A72A51EE47B7CA0A81711749C00:FG=1;"
        if !storedCookie.contains("smallFlowVersion=old") {
            storedCookie += ";smallFlowVersion=old;"
        }
        return storedCookie
    }

    // MARK: - Private helpers

    private func sendTranslateRequest(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        guard let gtk else {
            completion(result, QueryError.error(type: .api, message: "Get token failed."))
            return
        }

        let sign = jsFunction.call(withArguments: [text, gtk])?.toString()
        let url = "\(kBaiduTranslateURL)/v2transapi"
        let params: [String: Any] = [
            "from": languageCode(forLanguage: from) ?? "",
            "to": languageCode(forLanguage: to) ?? "",
            "query": text,
            "simple_means_flag": 3,
            "transtype": "realtime",
            "domain": "common",
            "sign": sign ?? "",
            "token": token ?? "",
        ]

        let headers: [String: String] = [
            "User-Agent": EZUserAgent,
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "Cookie": cookie,
        ]

        for (key, value) in headers {
            jsonSession.requestSerializer.setValue(value, forHTTPHeaderField: key)
        }

        let task = jsonSession.post(
            url,
            parameters: params,
            constructingBodyWith: nil,
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self else { return }
                parseResponseObject(responseObject, completion: completion)
            },
            failure: { [weak self] _, error in
                guard let self else { return }
                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }
                completion(result, QueryError.error(type: .api))
            }
        )

        queryModel.setStop({ task?.cancel() }, serviceType: serviceType().rawValue)
    }

    private func parseResponseObject(
        _ responseObject: Any?,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        if queryModel.isServiceStopped(serviceType().rawValue) {
            return
        }

        guard let currentResult = result else {
            completion(result, QueryError.error(type: .api))
            return
        }

        var message: String?

        if let responseObject,
           let response = EZBaiduTranslateResponse.mj_object(withKeyValues: responseObject)
           as? EZBaiduTranslateResponse {
            if response.error == 0 {
                error997Count = 0
                parseDictionaryResult(response, result: currentResult)
                parseTranslationResult(response, result: currentResult)
                currentResult.raw = responseObject

                if currentResult.wordResult != nil || currentResult.translatedResults != nil {
                    completion(currentResult, nil)
                    return
                }

                message = "百度翻译结果为空"
                return
            } else if response.error == 997 {
                error997Count += 1
                if error997Count < 3 {
                    token = nil
                    gtk = nil
                    translate(
                        queryModel.queryText,
                        from: queryModel.queryFromLanguage,
                        to: queryModel.queryTargetLanguage,
                        completion: completion
                    )
                    return
                } else {
                    message = "百度翻译获取 token 失败"
                }
            } else {
                message = "错误码 \(response.error)"
            }
        }

        updateCookieAndToken()
        completion(currentResult, QueryError.error(type: .api, message: message))
    }

    private func parseDictionaryResult(
        _ response: EZBaiduTranslateResponse,
        result: EZQueryResult
    ) {
        guard let simpleMeans = response.dict_result?.simple_means else { return }

        let wordResult = EZTranslateWordResult()

        var tags: [String] = []
        let simpleTags = simpleMeans.tags
        if let core = simpleTags.core { tags.append(contentsOf: core) }
        if let other = simpleTags.other {
            tags.append(contentsOf: other.filter { !$0.isEmpty })
        }
        if !tags.isEmpty {
            wordResult.tags = tags
        }

        if let symbol = simpleMeans.symbols.first {
            var phonetics: [EZWordPhonetic] = []
            let language = queryModel.queryFromLanguage

            if !symbol.ph_am.isEmpty {
                let phonetic = EZWordPhonetic()
                phonetic.name = NSLocalizedString("us_phonetic", comment: "")
                phonetic.language = language
                phonetic.accent = "us"
                phonetic.word = queryModel.queryText
                phonetic.value = symbol.ph_am
                phonetic.speakURL = getAudioURL(with: result.queryText, langCode: "en")
                phonetics.append(phonetic)
            }

            if !symbol.ph_en.isEmpty {
                let phonetic = EZWordPhonetic()
                phonetic.name = NSLocalizedString("uk_phonetic", comment: "")
                phonetic.language = language
                phonetic.accent = "uk"
                phonetic.word = queryModel.queryText
                phonetic.value = symbol.ph_en
                phonetic.speakURL = getAudioURL(with: result.queryText, langCode: "uk")
                phonetics.append(phonetic)
            }

            if !phonetics.isEmpty {
                wordResult.phonetics = phonetics
            }

            let parts = symbol.parts.compactMap { part -> EZTranslatePart? in
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
            if !parts.isEmpty {
                wordResult.parts = parts
            }

            let exchange = simpleMeans.exchange
            var exchanges: [EZTranslateExchange] = []
            let wordThird = (exchange.word_third as? [String]) ?? []
            if !wordThird.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("singular", comment: "")
                ex.words = wordThird
                exchanges.append(ex)
            }
            let wordPl = (exchange.word_pl as? [String]) ?? []
            if !wordPl.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("plural", comment: "")
                ex.words = wordPl
                exchanges.append(ex)
            }
            let wordEr = (exchange.word_er as? [String]) ?? []
            if !wordEr.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("comparative", comment: "")
                ex.words = wordEr
                exchanges.append(ex)
            }
            let wordEst = (exchange.word_est as? [String]) ?? []
            if !wordEst.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("superlative", comment: "")
                ex.words = wordEst
                exchanges.append(ex)
            }
            let wordPast = (exchange.word_past as? [String]) ?? []
            if !wordPast.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("past", comment: "")
                ex.words = wordPast
                exchanges.append(ex)
            }
            let wordDone = (exchange.word_done as? [String]) ?? []
            if !wordDone.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("past_participle", comment: "")
                ex.words = wordDone
                exchanges.append(ex)
            }
            let wordIng = (exchange.word_ing as? [String]) ?? []
            if !wordIng.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("present_participle", comment: "")
                ex.words = wordIng
                exchanges.append(ex)
            }
            let wordProto = (exchange.word_proto as? [String]) ?? []
            if !wordProto.isEmpty {
                let ex = EZTranslateExchange()
                ex.name = NSLocalizedString("root", comment: "")
                ex.words = wordProto
                exchanges.append(ex)
            }
            if !exchanges.isEmpty {
                wordResult.exchanges = exchanges
            }

            if let firstPart = simpleMeans.symbols.first?.parts.first,
               let means = firstPart.means as? [[String: Any]] {
                var simpleWords: [EZTranslateSimpleWord] = []
                for item in means {
                    guard item["isSeeAlso"] == nil else { continue }
                    guard let word = item["text"] as? String, !word.isEmpty else { continue }

                    let simpleWord = EZTranslateSimpleWord()
                    simpleWord.word = word
                    let part = (item["part"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "misc."
                    simpleWord.part = part
                    if let wordMeans = item["means"] as? [String] {
                        simpleWord.means = wordMeans
                    }
                    simpleWords.append(simpleWord)
                }

                if !simpleWords.isEmpty {
                    wordResult.simpleWords = simpleWords.sorted { lhs, rhs in
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

            let wordMeans = simpleMeans.word_means
            if let first = wordMeans.first {
                result.translatedResults = [(first as NSString).ns_trim() as String]
            }

            if wordResult.parts != nil || wordResult.simpleWords != nil {
                result.wordResult = wordResult
            }
        }
    }

    private func parseTranslationResult(
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

    private func sendGetTokenAndGtkRequest(completion: @escaping (String?, String?, Error?) -> ()) {
        let url = kBaiduTranslateURL

        let headers: [String: String] = [
            "Cookie": cookie,
        ]

        for (key, value) in headers {
            jsonSession.requestSerializer.setValue(value, forHTTPHeaderField: key)
            htmlSession.requestSerializer.setValue(value, forHTTPHeaderField: key)
        }

        htmlSession.get(
            url,
            parameters: nil,
            progress: nil,
            success: { _, responseObject in
                guard let data = responseObject as? Data,
                      let html = String(data: data, encoding: .utf8) else {
                    completion(nil, nil, QueryError.error(type: .api, message: "获取 token 失败"))
                    return
                }

                let tokenPattern = "token: '(.*?)',"
                let gtkPattern = "window.gtk = \"(.*?)\";"

                let token = html.getStringValue(withPattern: tokenPattern)
                let gtk = html.getStringValue(withPattern: gtkPattern)

                if let token, let gtk, !token.isEmpty, !gtk.isEmpty {
                    completion(token, gtk, nil)
                } else {
                    completion(nil, nil, QueryError.error(type: .api, message: "获取 token 失败"))
                }
            },
            failure: { _, _ in
                completion(nil, nil, QueryError.error(type: .api, message: "获取 token 失败"))
            }
        )
    }

    private func updateCookieAndToken() {
        Task {
            if let cookie = try? await CookieManager.shared.requestCookie(ofURL: kBaiduTranslateURL, name: "BAIDUID"),
               !cookie.isEmpty {
                let cookieString = "BAIDUID=\(cookie)"
                UserDefaults.standard.set(cookieString, forKey: kBaiduTranslateURL)
            }

            sendGetTokenAndGtkRequest { [weak self] token, gtk, _ in
                self?.token = token
                self?.gtk = gtk
            }
        }
    }

    private func getAudioURL(with text: String, langCode: String) -> String {
        let trimmed = (text as NSString).ns_trimToMaxLength(1000) as String
        let encoded = trimmed.ns_encode() as String

        let speed = (langCode == "zh") ? 5 : 3
        return "\(kBaiduTranslateURL)/gettts?text=\(encoded)&lan=\(langCode)&spd=\(speed)&source=web"
    }
}
