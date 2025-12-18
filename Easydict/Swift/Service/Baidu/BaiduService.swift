//
//  BaiduService.swift
//  Easydict
//
//  Created by tisfeng on 2025/03/09.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import AppKit
import JavaScriptCore

let kBaiduTranslateURL = "https://fanyi.baidu.com"

// MARK: - BaiduService

@objc(EZBaiduTranslate)
@objcMembers
final class BaiduService: QueryService {
    // MARK: Internal

    lazy var jsonSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        session.requestSerializer = AFHTTPRequestSerializer()
        let responseSerializer = AFJSONResponseSerializer()
        responseSerializer.acceptableContentTypes = ["application/json"]
        session.responseSerializer = responseSerializer
        return session
    }()

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
            let fromCode = languageCode(forLanguage: from).map(Language.init(rawValue:)) ?? from
            let toCode = languageCode(forLanguage: to).map(Language.init(rawValue:)) ?? to

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

    func getAudioURL(with text: String, langCode: String) -> String {
        let trimmed = (text as NSString).ns_trimToMaxLength(1000) as String
        let encoded = trimmed.ns_encode() as String

        let speed = (langCode == "zh") ? 5 : 3
        return "\(kBaiduTranslateURL)/gettts?text=\(encoded)&lan=\(langCode)&spd=\(speed)&source=web"
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
           let response = EZBaiduTranslateResponse.mj_object(withKeyValues: responseObject) {
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
}
