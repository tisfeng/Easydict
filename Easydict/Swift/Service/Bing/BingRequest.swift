//
//  BingRequest.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
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

    init(session: Session = .default) {
        self.session = session
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
        let context = TranslationContext(completion: completion)
        beginRequest(context.id)

        startTranslation(text: text, from: from, to: to, context: context, canRetryFetchHost: true)
    }

    func fetchTextToAudio(
        text: String,
        fromLanguage from: Language,
        accent: String?,
        requestID: UUID? = nil,
        completion: @escaping (Data?, Error?) -> ()
    ) {
        let isNewRequest = requestID == nil
        let requestID = requestID ?? beginRequest()
        if isNewRequest {
            // Translation may have refreshed the persisted host or token since the last speech request.
            bingConfig = BingConfig.loadFromUserDefaults()
        }
        fetchBingHost(requestID: requestID, callback: { [weak self] in
            guard let self = self else {
                completion(nil, CancellationError())
                return
            }

            fetchBingConfig(requestID: requestID) { [weak self] in
                guard let self = self else {
                    completion(nil, CancellationError())
                    return
                }

                let ssml = generateSSML(text: text, language: from, accent: accent)
                let parameters: [String: Any] = [
                    "ssml": ssml,
                    "token": bingConfig.token ?? "",
                    "key": bingConfig.key ?? "",
                ]

                guard let request = makeTTSRequest(
                    url: bingConfig.tfetttsURLString,
                    parameters: parameters,
                    requestID: requestID
                ) else {
                    completion(nil, CancellationError())
                    return
                }
                request.responseData { [weak self] response in
                    guard let self = self else {
                        completion(nil, CancellationError())
                        return
                    }
                    untrackRequest(request)
                    guard isCurrentTranslation(requestID) else {
                        completion(nil, CancellationError())
                        return
                    }

                    if let error = response.error {
                        if isCancelledError(error) {
                            completion(nil, CancellationError())
                            return
                        }
                        completion(nil, error)
                        return
                    }

                    let audioData = response.data
                    if response.response?.mimeType == kAudioMIMEType {
                        completion(audioData, nil)
                        return
                    }

                    // If host has changed, use new host to fetch again.
                    if let host = response.response?.url?.host, bingConfig.host != host {
                        logInfo("bing host changed: \(host)")
                        bingConfig.host = host
                        bingConfig.saveToUserDefaults()

                        fetchTextToAudio(
                            text: text, fromLanguage: from, accent: accent,
                            requestID: requestID, completion: completion
                        )
                    } else {
                        completion(nil, nil)
                    }
                }
            } failure: { error in
                completion(nil, error)
            }
        }, failure: { error in
            completion(nil, error)
        })
    }

    func translateTextFromDict(
        text: String,
        completion: @escaping ([String: Any]?, Error?) -> ()
    ) {
        let requestID = beginRequest()
        fetchBingHost(requestID: requestID, callback: { [weak self] in
            guard let self = self else {
                completion(nil, CancellationError())
                return
            }

            guard let request = makeDictTranslateRequest(
                url: bingConfig.dictTranslateURLString,
                parameters: ["q": text],
                requestID: requestID
            ) else {
                completion(nil, CancellationError())
                return
            }
            request.responseData { [weak self] response in
                guard let self = self else {
                    completion(nil, CancellationError())
                    return
                }
                untrackRequest(request)
                guard isCurrentTranslation(requestID) else {
                    completion(nil, CancellationError())
                    return
                }

                if let error = response.error {
                    if isCancelledError(error) {
                        completion(nil, CancellationError())
                        return
                    }
                    completion(nil, error)
                    return
                }

                guard let data = response.data,
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    completion(nil, QueryError(type: .api, message: "bing dict translate json parse fail"))
                    return
                }

                completion(dict, nil)
            }
        }, failure: { error in
            completion(nil, error)
        })
    }

    func reset() {
        cancelActiveRequests()
        bingConfig.resetToken()
    }

    func cancelActiveRequests() {
        activeRequestLock.lock()
        let requests = activeRequests
        activeRequests.removeAll()
        translationID = nil
        activeRequestLock.unlock()

        for request in requests {
            request.cancel()
        }
    }

    // MARK: Private

    // MARK: - Private Properties

    private var translationID: UUID?
    private let session: Session
    private let activeRequestLock = NSLock()
    private var activeRequests: [Request] = []
}

// MARK: - BingRequest Translation

extension BingRequest {
    // Responses arrive on the main queue; each query owns its completion.
    private final class TranslationContext {
        // MARK: Lifecycle

        init(completion: @escaping BingTranslateCompletion) {
            self.completion = completion
        }

        // MARK: Internal

        let id = UUID()
        var translateData: Data?
        var lookupData: Data?
        var translateError: Error?
        var lookupError: Error?
        var responseCount = 0

        func finish(_ translateData: Data?, _ lookupData: Data?, _ translateError: Error?, _ lookupError: Error?) {
            completionLock.lock()
            let callback = completion
            completion = nil
            completionLock.unlock()
            callback?(translateData, lookupData, translateError, lookupError)
        }

        func resetResponses() {
            translateData = nil
            lookupData = nil
            translateError = nil
            lookupError = nil
            responseCount = 0
        }

        // MARK: Private

        private let completionLock = NSLock()
        private var completion: BingTranslateCompletion?
    }

    private func startTranslation(
        text: String,
        from: String,
        to: String,
        context: TranslationContext,
        canRetryFetchHost: Bool
    ) {
        let completion: BingTranslateCompletion =
            { [weak self] translateData, lookupData, translateError, lookupError in
                guard let self, isCurrentTranslation(context.id) else {
                    context.finish(nil, nil, CancellationError(), nil)
                    return
                }
                context.finish(translateData, lookupData, translateError, lookupError)
            }
        let executeCallback = { [weak self] in
            guard let self else {
                completion(nil, nil, CancellationError(), nil)
                return
            }
            context.responseCount += 1
            guard context.responseCount == 2 else { return }
            guard isCurrentTranslation(context.id) else {
                completion(nil, nil, CancellationError(), nil)
                return
            }

            // An empty response pair can indicate a stale host after a network change.
            if canRetryFetchHost,
               context.translateData?.isEmpty == true,
               context.lookupData?.isEmpty == true {
                bingConfig.resetToken()
                bingConfig.host = nil
                bingConfig.saveToUserDefaults()
                context.resetResponses()
                startTranslation(text: text, from: from, to: to, context: context, canRetryFetchHost: false)
                return
            }
            completion(context.translateData, context.lookupData, context.translateError, context.lookupError)
        }

        let requestID = context.id
        fetchBingHost(requestID: requestID, callback: { [weak self] in
            guard let self = self else {
                completion(nil, nil, CancellationError(), nil)
                return
            }

            guard isCurrentTranslation(context.id) else {
                completion(nil, nil, CancellationError(), nil)
                return
            }

            fetchBingConfig(requestID: requestID) { [weak self] in
                guard let self = self else {
                    completion(nil, nil, CancellationError(), nil)
                    return
                }

                guard isCurrentTranslation(context.id) else {
                    completion(nil, nil, CancellationError(), nil)
                    return
                }

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

                guard sendTranslateRequest(
                    parameters: translateParameters,
                    context: context,
                    completion: completion,
                    didRespond: executeCallback
                ) else { return }

                var dictParameters = parameters
                dictParameters["from"] = from
                sendLookupRequest(
                    parameters: dictParameters,
                    context: context,
                    completion: completion,
                    didRespond: executeCallback
                )
            } failure: { error in
                completion(nil, nil, error, nil)
            }
        }, failure: { error in
            completion(nil, nil, error, nil)
        })
    }

    private func sendTranslateRequest(
        parameters: Parameters,
        context: TranslationContext,
        completion: @escaping BingTranslateCompletion,
        didRespond: @escaping () -> ()
    )
        -> Bool {
        guard let translateRequest = makeTranslateRequest(
            url: bingConfig.ttranslatev3URLString,
            parameters: parameters,
            requestID: context.id
        ) else {
            completion(nil, nil, CancellationError(), nil)
            return false
        }
        translateRequest.responseData { [weak self] response in
            guard let self = self else {
                completion(nil, nil, CancellationError(), nil)
                return
            }
            untrackRequest(translateRequest)

            if let error = response.error {
                if isCancelledError(error) {
                    context.translateError = CancellationError()
                    didRespond()
                    return
                }

                // if this problem occurs, you can try switching networks
                // if you use a VPN, you can try replacing nodes，or try adding `bing.com` into a direct rule
                // https://immersivetranslate.com/docs/faq/#429-%E9%94%99%E8%AF%AF
                if response.response?.statusCode == 429 {
                    context.translateError = QueryError(
                        type: .api,
                        message: "429 error, Bing translate too many requests"
                    )
                } else {
                    context.translateError = error
                }
                didRespond()
                return
            }

            guard let data = response.data else {
                context.translateError = QueryError(
                    type: .api,
                    message: "bing translate responseObject is not Data"
                )
                didRespond()
                return
            }

            context.translateData = data
            didRespond()
        }
        return true
    }

    private func sendLookupRequest(
        parameters: Parameters,
        context: TranslationContext,
        completion: @escaping BingTranslateCompletion,
        didRespond: @escaping () -> ()
    ) {
        guard let lookupRequest = makeTranslateRequest(
            url: bingConfig.tlookupv3URLString,
            parameters: parameters,
            requestID: context.id
        ) else {
            completion(nil, nil, CancellationError(), nil)
            return
        }
        lookupRequest.responseData { [weak self] response in
            guard let self = self else {
                completion(nil, nil, CancellationError(), nil)
                return
            }
            untrackRequest(lookupRequest)

            if let error = response.error {
                if isCancelledError(error) {
                    context.lookupError = CancellationError()
                    didRespond()
                    return
                }

                logError("bing lookup error: \(error)")
                context.lookupError = error
                didRespond()
                return
            }

            guard let data = response.data else {
                context.lookupError = QueryError(type: .api, message: "bing lookup responseObject is not Data")
                didRespond()
                return
            }

            context.lookupData = data
            didRespond()
        }
    }
}

// MARK: - BingRequest Configuration

extension BingRequest {
    private func fetchBingHost(requestID: UUID, callback: @escaping () -> (), failure: @escaping (Error) -> ()) {
        guard isCurrentTranslation(requestID) else {
            failure(CancellationError())
            return
        }
        if bingConfig.host != nil {
            callback()
            return
        }

        // For www.bing.com, sometimes it won't return redirect URL, so we use cn.bing.com
        let webBingURLString = "http://\(BingConfig.chinaHost)"

        guard let request = makeTranslateRequest(url: webBingURLString, requestID: requestID) else {
            failure(CancellationError())
            return
        }
        request.responseData { [weak self] response in
            guard let self = self else {
                failure(CancellationError())
                return
            }
            untrackRequest(request)
            guard isCurrentTranslation(requestID) else {
                failure(CancellationError())
                return
            }

            if let error = response.error {
                if isCancelledError(error) {
                    failure(CancellationError())
                    return
                }

                bingConfig.host = BingConfig.chinaHost
                bingConfig.saveToUserDefaults()
                callback()
                return
            }

            let host = response.response?.url?.host ?? BingConfig.chinaHost
            bingConfig.host = host
            bingConfig.saveToUserDefaults()
            logInfo("bing host: \(host)")
            callback()
        }
    }

    private func fetchBingConfig(requestID: UUID, callback: @escaping () -> (), failure: @escaping (Error) -> ()) {
        guard isCurrentTranslation(requestID) else {
            failure(CancellationError())
            return
        }
        if !bingConfig.isBingTokenExpired() {
            callback()
            return
        }

        let url = bingConfig.translatorURLString
        guard let request = makeHTMLRequest(url: url, requestID: requestID) else {
            failure(CancellationError())
            return
        }
        request.responseData { [weak self] response in
            guard let self = self else {
                failure(CancellationError())
                return
            }
            untrackRequest(request)
            guard isCurrentTranslation(requestID) else {
                failure(CancellationError())
                return
            }

            if let error = response.error {
                if isCancelledError(error) {
                    failure(CancellationError())
                    return
                }
                failure(error)
                return
            }

            guard let data = response.data else {
                let error = QueryError(type: .api, message: "bing htmlSession responseObject is not Data")
                failure(error)
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
        }
    }
}

// MARK: - BingRequest Request Management

extension BingRequest {
    @discardableResult
    private func beginRequest(_ id: UUID = UUID()) -> UUID {
        activeRequestLock.lock()
        let requests = activeRequests
        activeRequests.removeAll()
        translationID = id
        activeRequestLock.unlock()
        requests.forEach { $0.cancel() }
        return id
    }

    private func isCurrentTranslation(_ id: UUID) -> Bool {
        activeRequestLock.lock()
        defer { activeRequestLock.unlock() }
        return translationID == id
    }

    @discardableResult
    private func makeHTMLRequest(
        url: String,
        parameters: Parameters? = nil,
        requestID: UUID
    )
        -> DataRequest? {
        makeRequest(
            url: url,
            method: .get,
            parameters: parameters,
            headers: requestHeaders(),
            requestID: requestID
        )
    }

    @discardableResult
    private func makeTranslateRequest(
        url: String,
        parameters: Parameters? = nil,
        requestID: UUID
    )
        -> DataRequest? {
        makeRequest(
            url: url,
            method: parameters == nil ? .get : .post,
            parameters: parameters,
            headers: requestHeaders(includeCookie: true),
            requestID: requestID
        )
    }

    @discardableResult
    private func makeTTSRequest(
        url: String,
        parameters: Parameters,
        requestID: UUID
    )
        -> DataRequest? {
        makeRequest(
            url: url,
            method: .post,
            parameters: parameters,
            headers: requestHeaders(includeCookie: true),
            requestID: requestID
        )
    }

    @discardableResult
    private func makeDictTranslateRequest(
        url: String,
        parameters: Parameters,
        requestID: UUID
    )
        -> DataRequest? {
        makeRequest(
            url: url,
            method: .get,
            parameters: parameters,
            headers: requestHeaders(includeCookie: true),
            requestID: requestID
        )
    }

    @discardableResult
    private func makeRequest(
        url: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        headers: HTTPHeaders,
        requestID: UUID
    )
        -> DataRequest? {
        activeRequestLock.lock()
        defer { activeRequestLock.unlock() }
        guard translationID == requestID else { return nil }
        let encoding: ParameterEncoding = method == .get ? URLEncoding.default : URLEncoding.httpBody
        let request = session.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            requestModifier: { request in
                request.timeoutInterval = AppConstants.networkTimeoutInterval
            }
        )
        .validate(statusCode: 200 ..< 300)

        activeRequests.append(request)
        return request
    }

    private func requestHeaders(includeCookie: Bool = false) -> HTTPHeaders {
        var headers = HTTPHeaders([
            "User-Agent": AppConstants.userAgent,
        ])

        if includeCookie, !bingConfig.cookie.isEmpty {
            headers.add(name: "Cookie", value: bingConfig.cookie)
        }

        return headers
    }

    private func isCancelledError(_ error: Error) -> Bool {
        if let error = error as? AFError {
            return error.isExplicitlyCancelledError || error.underlyingError.map(isCancelledError) == true
        }
        return error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    private func untrackRequest(_ request: Request) {
        activeRequestLock.lock()
        activeRequests.removeAll { trackedRequest in
            trackedRequest.id == request.id
        }
        activeRequestLock.unlock()
    }
}

// MARK: - BingRequest Content Helpers

extension BingRequest {
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
        var trimText = text.trimToMaxLength(7000)
        // Chinese text should be shorter, long TTS will cost much time.
        if !EZLanguageManager.shared().isLanguageWordsNeedSpace(language) {
            trimText = text.trimToMaxLength(2000)
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
    func getStringValue(withPattern pattern: String) -> String? {
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

    func escapeXMLEntities() -> String {
        var result = self
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        return result
    }
}
