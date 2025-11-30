//
//  BingRequest.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import Foundation

private let kAudioMIMEType = "audio/mpeg"

// MARK: - BingTranslateCompletion

typealias BingTranslateCompletion = (
    _ translateData: Data?,
    _ lookupData: Data?,
    _ translateError: Error?,
    _ lookupError: Error?
)
    -> ()

// MARK: - BingRequest

class BingRequest {
    // MARK: Lifecycle

    init() {
        self.bingConfig = BingConfig.loadFromUserDefaults()
    }

    // MARK: Internal

    // MARK: - Public Properties

    private(set) var bingConfig: BingConfig

    // MARK: - Public Methods

    func translateText(
        text: String,
        from: String,
        to: String,
        completionHandler completion: @escaping BingTranslateCompletion
    ) {
        self.from = from
        self.to = to
        self.text = text
        self.completion = completion

        fetchBingHost { [weak self] in
            guard let self = self else { return }

            fetchBingConfig { [weak self] in
                guard let self = self else { return }

                let parameters: [String: Any] = [
                    "text": text,
                    "to": to,
                    "token": bingConfig.token ?? "",
                    "key": bingConfig.key ?? "",
                ]

                // Get translate data
                var translateParameters = parameters
                translateParameters["fromLang"] = from
                translateParameters["tryFetchingGenderDebiasedTranslations"] = "true"

                translateSession.post(
                    bingConfig.ttranslatev3URLString,
                    parameters: translateParameters,
                    progress: nil,
                    success: { [weak self] _, responseObject in
                        guard let self = self else { return }

                        guard let data = responseObject as? Data else {
                            translateError = QueryError(
                                type: .api,
                                message: "bing translate responseObject is not Data"
                            )
                            logWarn("bing translate responseObject type: \(type(of: responseObject))")
                            executeCallback()
                            return
                        }
                        translateData = data
                        executeCallback()
                    },
                    failure: { [weak self] task, error in
                        guard let self = self else { return }

                        let response = task?.response as? HTTPURLResponse
                        // if this problem occurs, you can try switching networks
                        // if you use a VPN, you can try replacing nodes，or try adding `bing.com` into a direct rule
                        // https://immersivetranslate.com/docs/faq/#429-%E9%94%99%E8%AF%AF
                        if response?.statusCode == 429 {
                            translateError = QueryError(
                                type: .api,
                                message: "429 error, Bing translate too many requests"
                            )
                        } else {
                            translateError = error
                        }
                        executeCallback()
                    }
                )

                // Get lookup data
                var dictParameters = parameters
                dictParameters["from"] = from

                translateSession.post(
                    bingConfig.tlookupv3URLString,
                    parameters: dictParameters,
                    progress: nil,
                    success: { [weak self] _, responseObject in
                        guard let self = self else { return }

                        guard let data = responseObject as? Data else {
                            lookupError = QueryError(type: .api, message: "bing lookup responseObject is not Data")
                            logWarn("bing lookup responseObject type: \(type(of: responseObject))")
                            executeCallback()
                            return
                        }
                        lookupData = data
                        executeCallback()
                    },
                    failure: { [weak self] _, error in
                        guard let self = self else { return }

                        logError("bing lookup error: \(error)")
                        lookupError = error
                        executeCallback()
                    }
                )
            } failure: { error in
                completion(nil, nil, error, nil)
            }
        }
    }

    func fetchTextToAudio(
        text: String,
        fromLanguage from: Language,
        accent: String?,
        completion: @escaping (Data?, Error?) -> ()
    ) {
        fetchBingHost { [weak self] in
            guard let self = self else { return }

            fetchBingConfig { [weak self] in
                guard let self = self else { return }

                let ssml = generateSSML(text: text, language: from, accent: accent)
                let parameters: [String: Any] = [
                    "ssml": ssml,
                    "token": bingConfig.token ?? "",
                    "key": bingConfig.key ?? "",
                ]

                ttsSession.post(
                    bingConfig.tfetttsURLString,
                    parameters: parameters,
                    progress: nil,
                    success: { [weak self] task, responseObject in
                        guard let self = self else { return }

                        let audioData = responseObject as? Data
                        if task.response?.mimeType == kAudioMIMEType {
                            completion(audioData, nil)
                        } else {
                            // If host has changed, use new host to fetch again.
                            if let host = task.response?.url?.host, bingConfig.host != host {
                                logInfo("bing host changed: \(host)")
                                bingConfig.host = host
                                bingConfig.saveToUserDefaults()

                                fetchTextToAudio(text: text, fromLanguage: from, accent: accent, completion: completion)
                                return
                            } else {
                                completion(nil, nil)
                            }
                        }
                    },
                    failure: { _, error in
                        completion(nil, error)
                    }
                )
            } failure: { error in
                completion(nil, error)
            }
        }
    }

    func translateTextFromDict(
        text: String,
        completion: @escaping ([String: Any]?, Error?) -> ()
    ) {
        fetchBingHost { [weak self] in
            guard let self = self else { return }

            dictTranslateSession.get(
                bingConfig.dictTranslateURLString,
                parameters: ["q": text],
                progress: nil,
                success: { _, responseObject in
                    guard let dict = responseObject as? [String: Any] else {
                        completion(nil, QueryError(type: .api, message: "bing dict translate json parse fail"))
                        return
                    }
                    completion(dict, nil)
                },
                failure: { _, error in
                    completion(nil, error)
                }
            )
        }
    }

    func reset() {
        bingConfig.resetToken()
        resetData()
    }

    // MARK: Private

    // MARK: - Private Properties

    private var translateData: Data?
    private var lookupData: Data?
    private var translateError: Error?
    private var lookupError: Error?
    private var responseCount = 0

    private var from: String = ""
    private var to: String = ""
    private var text: String = ""
    private var completion: BingTranslateCompletion?

    private var canRetryFetchHost = true

    // MARK: - Lazy Sessions

    private lazy var htmlSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(EZUserAgent, forHTTPHeaderField: "User-Agent")
        session.requestSerializer = requestSerializer
        let responseSerializer = AFHTTPResponseSerializer()
        responseSerializer.acceptableContentTypes = Set(["text/html"])
        session.responseSerializer = responseSerializer
        return session
    }()

    private lazy var translateSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(EZUserAgent, forHTTPHeaderField: "User-Agent")
        requestSerializer.setValue(bingConfig.cookie, forHTTPHeaderField: "Cookie")
        session.requestSerializer = requestSerializer
        session.responseSerializer = AFHTTPResponseSerializer()
        return session
    }()

    private lazy var ttsSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(EZUserAgent, forHTTPHeaderField: "User-Agent")
        requestSerializer.setValue(bingConfig.cookie, forHTTPHeaderField: "Cookie")
        session.requestSerializer = requestSerializer
        let responseSerializer = AFHTTPResponseSerializer()
        responseSerializer.acceptableContentTypes = Set([kAudioMIMEType])
        session.responseSerializer = responseSerializer
        return session
    }()

    private lazy var dictTranslateSession: AFHTTPSessionManager = {
        let session = AFHTTPSessionManager()
        let requestSerializer = AFHTTPRequestSerializer()
        requestSerializer.setValue(EZUserAgent, forHTTPHeaderField: "User-Agent")
        requestSerializer.setValue(bingConfig.cookie, forHTTPHeaderField: "Cookie")
        session.requestSerializer = requestSerializer
        session.responseSerializer = AFJSONResponseSerializer()
        return session
    }()

    // MARK: - Private Methods

    private func executeCallback() {
        responseCount += 1
        if responseCount >= 2 {
            // Through testing, after switching to a different IP in a different country, the previous host might not return an error, but data is empty.
            // So we need to re-fetch the host.
            // But this scenario is not guaranteed to be a host issue, so retry once.
            if canRetryFetchHost,
               translateData != nil, translateData?.isEmpty == true,
               lookupData != nil, lookupData?.isEmpty == true {
                reset()
                canRetryFetchHost = false
                bingConfig.host = nil
                bingConfig.saveToUserDefaults()
                translateText(text: text, from: from, to: to, completionHandler: completion ?? { _, _, _, _ in })
                return
            }

            if let completion = completion {
                completion(translateData, lookupData, translateError, lookupError)
                canRetryFetchHost = true
            }
            resetData()
        }
    }

    private func fetchBingHost(callback: @escaping () -> ()) {
        if bingConfig.host != nil {
            callback()
            return
        }

        // For www.bing.com, sometimes it won't return redirect URL, so we use cn.bing.com
        let webBingURLString = "http://\(BingConfig.chinaHost)"

        translateSession.get(
            webBingURLString,
            parameters: nil,
            progress: nil,
            success: { [weak self] task, _ in
                guard let self = self else { return }

                let host = task.response?.url?.host ?? BingConfig.chinaHost
                bingConfig.host = host
                bingConfig.saveToUserDefaults()
                logInfo("bing host: \(host)")
                callback()
            },
            failure: { [weak self] _, _ in
                guard let self = self else { return }

                bingConfig.host = BingConfig.chinaHost
                bingConfig.saveToUserDefaults()
                callback()
            }
        )
    }

    private func fetchBingConfig(callback: @escaping () -> (), failure: @escaping (Error) -> ()) {
        if !bingConfig.isBingTokenExpired() {
            callback()
            return
        }

        let url = bingConfig.translatorURLString
        htmlSession.get(
            url,
            parameters: nil,
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self = self else { return }

                guard let data = responseObject as? Data else {
                    let error = QueryError(type: .api, message: "bing htmlSession responseObject is not Data")
                    failure(error)
                    logWarn("bing html responseObject type is \(type(of: responseObject))")
                    return
                }

                guard let responseString = String(data: data, encoding: .utf8) else {
                    let error = QueryError(type: .api, message: "bing html response string is nil")
                    failure(error)
                    return
                }

                guard let ig = getIGValue(from: responseString), !ig.isEmpty else {
                    let error = QueryError(type: .api, message: "bing IG is empty")
                    failure(error)
                    return
                }
                logInfo("bing IG: \(ig)")

                guard let iid = getDataIidValue(from: responseString), !iid.isEmpty else {
                    let error = QueryError(type: .api, message: "bing IID is empty")
                    failure(error)
                    return
                }
                logInfo("bing IID: \(iid)")

                guard let arr = getParamsAbusePreventionHelperArray(from: responseString), arr.count == 3 else {
                    let error = QueryError(type: .api, message: "bing get key and token failed")
                    failure(error)
                    return
                }

                let key = arr[0]
                guard !key.isEmpty else {
                    let error = QueryError(type: .api, message: "bing key is empty")
                    failure(error)
                    return
                }

                let token = arr[1]
                guard !token.isEmpty else {
                    let error = QueryError(type: .api, message: "bing token is empty")
                    failure(error)
                    return
                }
                logInfo("bing key: \(key)")
                logInfo("bing token: \(token)")

                let expirationInterval = arr[2]

                bingConfig.IG = ig
                bingConfig.IID = iid
                bingConfig.key = key
                bingConfig.token = token
                bingConfig.expirationInterval = expirationInterval
                bingConfig.saveToUserDefaults()
                callback()
            },
            failure: { _, error in
                failure(error)
            }
        )
    }

    private func resetData() {
        translateData = nil
        lookupData = nil
        translateError = nil
        responseCount = 0
    }

    // MARK: - Regex Helpers

    private func getIGValue(from htmlString: String) -> String? {
        // IG:"8E24D5A82C3240C8A68683C2484870E6",
        let pattern = #"IG:\s*"([^"]+)""#
        return htmlString.getStringValue(withPattern: pattern)
    }

    private func getParamsAbusePreventionHelperArray(from htmlString: String) -> [String]? {
        // var params_AbusePreventionHelper = [1693880687457,"0T_WDBmVBWjrlS5lBJPS6KYPLOboyyrf",3600000];
        let pattern = #"params_AbusePreventionHelper\s*=\s*\[([^\]]+)\]"#
        guard let arrayString = htmlString.getStringValue(withPattern: pattern) else {
            return nil
        }
        let cleanedString = arrayString.replacingOccurrences(of: "\"", with: "")
        return cleanedString.components(separatedBy: ",")
    }

    private func getDataIidValue(from htmlString: String) -> String? {
        // data-iid="translator.5029"
        let pattern = #"data-iid\s*=\s*"([^"]+)""#
        return htmlString.getStringValue(withPattern: pattern)
    }

    // MARK: - SSML Generation

    /// Generate ssml with text and language.
    /// Docs: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/speech-synthesis-markup-structure#speak-examples
    private func generateSSML(text: String, language: Language, accent: String?) -> String {
        let voiceRate = "-10%" // bing web is -20%

        var languageVoice = BingLanguageVoice.languageVoices[language]

        /// Handle xml special characters, like ' < &
        /// Ref: https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/speech-synthesis-markup-structure#special-characters
        /// 1000 Chinese characters, is about 1MB, duration 4 minutes (mp3)
        /// 2000 Chinese characters, is about 1.9MB, duration 8 minutes
        /// 7000 English characters, is about 2MB, duration 8 minutes
        var trimText = (text as NSString).trim(toMaxLength: 7000) as String
        // Chinese text should be shorter, long TTS will cost much time.
        if !EZLanguageManager.shared().isLanguageWordsNeedSpace(language) {
            trimText = (text as NSString).trim(toMaxLength: 2000) as String
        }

        let escapedXMLText = trimText.escapeXMLEntities()

        // Handle uk accent
        if language == .english, accent == "uk" {
            languageVoice = BingLanguageVoice(lang: "en-GB", voiceName: "en-GB-SoniaNeural")
        }

        let lang = languageVoice?.lang ?? "en-US"
        let voiceName = languageVoice?.voiceName ?? "en-US-JennyNeural"

        let ssml = """
        <speak version="1.0" xml:lang='\(lang)'>\
        <voice name='\(voiceName)'>\
        <prosody rate='\(voiceRate)'>\(escapedXMLText)</prosody>\
        </voice>\
        </speak>
        """

        return ssml
    }
}

// MARK: - String Regex Extension

extension String {
    fileprivate func getStringValue(withPattern pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              match.numberOfRanges >= 2
        else {
            return nil
        }

        if let range = Range(match.range(at: 1), in: self) {
            return String(self[range])
        }
        return nil
    }

    fileprivate func escapeXMLEntities() -> String {
        var result = self
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        return result
    }
}
