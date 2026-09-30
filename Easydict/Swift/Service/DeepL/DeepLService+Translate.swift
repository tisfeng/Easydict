//
//  DeepLService+Translate.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

private let kDeepLWebURL = "https://oneshot-free.www.deepl.com/v1/translate"
private let kDeepLWebOSVersion = "26.0"
private let kDeepLWebAppBuild = "5443737"
private let kDeepLWebInstanceID = UUID().uuidString.lowercased()
private let kDeepLWebSessionID = UUID().uuidString.lowercased()

// MARK: - DeepLService + Translate

extension DeepLService {
    // MARK: - Web Translate

    /// Translates text through DeepL's anonymous oneshot endpoint.
    ///
    /// The legacy JSON-RPC endpoint is no longer reliable. The oneshot request mirrors the
    /// request shape used by DeepL's interactive clients and returns the same `translations`
    /// payload as the official API.
    /// Reference: https://github.com/OwO-Network/DLX/issues/216 and
    /// https://github.com/OwO-Network/DLX/pull/217
    func deepLWebTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        let cancellation = DeepLWebTranslationCancellation()
        queryModel.setStop({
            cancellation.cancel()
        }, serviceType: serviceType().rawValue)

        Task { [weak self] in
            guard let self else {
                completion(QueryResult(), CancellationError())
                return
            }

            let appVersion = await DeepLWebAppVersionProvider.shared.currentVersion()
            guard !cancellation.isCancelled else {
                completion(QueryResult(), CancellationError())
                return
            }

            performDeepLWebTranslate(
                text,
                from: from,
                to: to,
                context: DeepLWebTranslationContext(
                    appVersion: appVersion,
                    cancellation: cancellation
                ),
                completion: completion
            )
        }
    }

    private func performDeepLWebTranslate(
        _ text: String,
        from: Language,
        to: Language,
        context: DeepLWebTranslationContext,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        guard !context.cancellation.isCancelled else {
            completion(QueryResult(), CancellationError())
            return
        }

        let sourceLanguageCode = languageCode(for: from) ?? "auto"
        guard let targetLanguageCode = languageCode(for: to),
              targetLanguageCode != "auto"
        else {
            completion(result, QueryError(type: .api, message: "Invalid DeepL target language"))
            return
        }

        let requestBody = DeepLWebTranslateRequest(
            text: [text],
            targetLang: oneshotLanguageCode(targetLanguageCode, isTarget: true),
            sourceLang: sourceLanguageCode == "auto"
                ? nil
                : oneshotLanguageCode(sourceLanguageCode, isTarget: false),
            usageType: "translate",
            appInformation: DeepLAppInformation(
                os: "iOS",
                osVersion: kDeepLWebOSVersion,
                appVersion: context.appVersion,
                appBuild: kDeepLWebAppBuild,
                instanceID: kDeepLWebInstanceID
            )
        )

        guard let postData = try? JSONEncoder().encode(requestBody),
              let url = URL(string: kDeepLWebURL)
        else {
            completion(result, QueryError(type: .api, message: "Failed to serialize request"))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData
        request.timeoutInterval = EZNetWorkTimeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("None", forHTTPHeaderField: "Authorization")
        request.setValue(
            deepLWebUserAgent(appVersion: context.appVersion),
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue(kDeepLWebOSVersion, forHTTPHeaderField: "x-app-os-version")
        request.setValue(kDeepLWebInstanceID, forHTTPHeaderField: "x-app-instance-id")
        request.setValue(kDeepLWebSessionID, forHTTPHeaderField: "x-app-session-id")

        let startTime = CFAbsoluteTimeGetCurrent()

        let dataRequest = AF.request(request)
            .validate(statusCode: 200 ..< 300)

        guard context.cancellation.install(dataRequest) else {
            completion(QueryResult(), CancellationError())
            return
        }

        dataRequest.responseData { [weak self] response in
            guard let self = self else {
                completion(QueryResult(), CancellationError())
                return
            }

            if queryModel.isServiceStopped(serviceType().rawValue) {
                completion(result, CancellationError())
                return
            }

            if let nsError = response.error as? NSError, nsError.code == NSURLErrorCancelled {
                completion(result, CancellationError())
                return
            }

            if let error = response.error {
                logError("deepLWebTranslate error: \(error)")
                var queryError = QueryError(type: .api, message: error.localizedDescription)

                // If web first and has auth key, try official API
                let useOfficialAPI = !Defaults[.deepLAuth].isEmpty &&
                    (Defaults[.deepLTranslation] == .webFirst)
                if useOfficialAPI {
                    deepLTranslate(text, from: from, to: to, completion: completion)
                    return
                }

                if let errorMessage = parseDeepLErrorMessage(from: response.data) {
                    queryError = QueryError(type: .api, message: nil, errorDataMessage: errorMessage)
                }

                completion(result, queryError)
                return
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            logInfo("deepLWebTranslate cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

            guard let responseData = response.data,
                  let responseDict = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any]
            else {
                completion(result, QueryError(type: .api, message: "Invalid response"))
                return
            }

            guard let translatedResults = parseOfficialResponse(responseDict), !translatedResults.isEmpty else {
                completion(result, QueryError(type: .api, message: "Failed to parse response"))
                return
            }

            result.translatedResults = translatedResults
            result.raw = responseDict as NSDictionary
            completion(result, nil)
        }
    }

    // MARK: - Official API Translate

    /// DeepL official API translate.
    /// Docs: https://www.deepl.com/zh/docs-api/translating-text
    func deepLTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, (any Error)?) -> ()
    ) {
        var sourceLangCode = languageCode(for: from) ?? "auto"
        sourceLangCode = removeLanguageVariant(sourceLangCode)

        let targetLangCode = languageCode(for: to) ?? ""

        let authKey = Defaults[.deepLAuth]

        // DeepL api free and deepL pro api use different url host.
        let isFreeKey = authKey.hasSuffix(":fx")
        let host = isFreeKey ? "https://api-free.deepl.com" : "https://api.deepl.com"
        var url = "\(host)/v2/translate"

        let endPoint = Defaults[.deepLTranslateEndPointKey]
        if !endPoint.isEmpty {
            url = endPoint
        }

        let params: [String: Any] = [
            "text": text,
            "source_lang": sourceLangCode,
            "target_lang": targetLangCode,
        ]

        let authorization = "DeepL-Auth-Key \(authKey)"
        let startTime = CFAbsoluteTimeGetCurrent()
        let request = AF.request(
            url,
            method: .post,
            parameters: params,
            encoding: URLEncoding.httpBody,
            headers: HTTPHeaders([
                "Authorization": authorization,
            ]),
            requestModifier: { request in
                request.timeoutInterval = EZNetWorkTimeoutInterval
            }
        )
        .validate(statusCode: 200 ..< 300)

        request.responseData { [weak self] response in
            guard let self = self else {
                completion(QueryResult(), CancellationError())
                return
            }

            if queryModel.isServiceStopped(serviceType().rawValue) {
                completion(result, CancellationError())
                return
            }

            if let error = response.error {
                if (error as NSError).code == NSURLErrorCancelled {
                    completion(result, CancellationError())
                    return
                }

                logError("deepLTranslate error: \(error)")

                if Defaults[.deepLTranslation] == .authKeyFirst {
                    deepLWebTranslate(text, from: from, to: to, completion: completion)
                    return
                }

                let queryError = QueryError(type: .api, message: error.localizedDescription)
                queryError.errorDataMessage = parseDeepLErrorMessage(from: response.data)
                completion(result, queryError)
                return
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            logInfo("deepLTranslate cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

            guard let responseData = response.data,
                  let responseDict = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any]
            else {
                completion(result, QueryError(type: .api, message: "Invalid response"))
                return
            }

            result.translatedResults = parseOfficialResponse(responseDict)
            result.raw = responseDict as NSDictionary
            completion(result, nil)
        }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }

    // MARK: - Official API Response Parser

    func parseOfficialResponse(_ responseDict: [String: Any]) -> [String]? {
        guard let responseData = try? JSONSerialization.data(withJSONObject: responseDict),
              let response = try? JSONDecoder().decode(DeepLOfficialResponse.self, from: responseData),
              let translatedText = response.translations?.first?.text,
              !translatedText.trim().isEmpty
        else {
            return nil
        }
        return translatedText.toParagraphs()
    }

    private func parseDeepLErrorMessage(from data: Data?) -> String? {
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        if let message = json["message"] as? String, !message.isEmpty {
            return message
        }
        if let title = json["title"] as? String, !title.isEmpty {
            return title
        }
        if let error = json["error"] as? String, !error.isEmpty {
            return error
        }
        if let errorDict = json["error"] as? [String: Any],
           let message = errorDict["message"] as? String,
           !message.isEmpty {
            return message
        }
        return nil
    }

    // MARK: - Request Helper Methods

    /// Converts Easydict's language codes to the BCP-47-like values accepted by oneshot.
    private func oneshotLanguageCode(_ languageCode: String, isTarget: Bool) -> String {
        switch languageCode.lowercased() {
        case "zh-hans": return "zh-Hans"
        case "zh-hant": return "zh-Hant"
        case "pt-pt": return "pt-PT"
        case "pt-br": return "pt-BR"
        case "en" where isTarget: return "en-US"
        default: return languageCode.lowercased()
        }
    }
}

private func deepLWebUserAgent(appVersion: String) -> String {
    "DeepL/\(appVersion) CFNetwork/3826.600.41 Darwin/25.0.0"
}

// MARK: - DeepLWebTranslationContext

private struct DeepLWebTranslationContext {
    let appVersion: String
    let cancellation: DeepLWebTranslationCancellation
}

// MARK: - DeepLWebTranslationCancellation

private final class DeepLWebTranslationCancellation: @unchecked Sendable {
    // MARK: Internal

    var isCancelled: Bool { lock.withLock { cancelled } }

    func cancel() {
        let cancelRequest = lock.withLock { () -> (() -> ())? in
            cancelled = true
            return cancelRequestHandler
        }
        cancelRequest?()
    }

    func install(_ request: DataRequest) -> Bool {
        let shouldCancel = lock.withLock {
            if cancelled { return true }
            cancelRequestHandler = { request.cancel() }
            return false
        }
        if shouldCancel { request.cancel() }
        return !shouldCancel
    }

    // MARK: Private

    private let lock = NSLock()
    private var cancelled = false
    private var cancelRequestHandler: (() -> ())?
}
