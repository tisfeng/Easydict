//
//  DeepLService+Translate.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import AFNetworking
import Defaults
import Foundation

private let kDeepLWebURL = "https://www2.deepl.com/jsonrpc"

// MARK: - DeepLService + Web Translate

extension DeepLService {
    // MARK: - DeepL Web Translate

    /// DeepL web translate.
    /// Ref: https://github.com/akl7777777/bob-plugin-akl-deepl-free-translate/blob/9d194783b3eb8b3a82f21bcfbbaf29d6b28c2761/src/main.js
    func deepLWebTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        var sourceLangCode = languageCode(for: from) ?? "auto"
        sourceLangCode = removeLanguageVariant(sourceLangCode)

        let regionalVariant = languageCode(for: to) ?? ""
        let targetLangCode = regionalVariant.components(separatedBy: "-").first ?? regionalVariant

        let requestID = getRandomNumber()
        let iCount = getICount(text)
        let timestamp = getTimestamp(iCount: iCount)

        var params: [String: Any] = [
            "texts": [["text": text, "requestAlternatives": 3]],
            "splitting": "newlines",
            "lang": ["source_lang_user_selected": sourceLangCode, "target_lang": targetLangCode],
            "timestamp": timestamp,
        ]

        if regionalVariant != targetLangCode {
            params["commonJobParams"] = [
                "regionalVariant": regionalVariant,
                "mode": "translate",
                "browserType": 1,
                "textType": "plaintext",
            ]
        }

        let postData: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "LMT_handle_texts",
            "id": requestID,
            "params": params,
        ]

        guard var postStr = postData.toJSONString() else {
            completion(result, QueryError(type: .api, message: "Failed to serialize request"))
            return
        }

        // Special handling for method spacing based on ID
        if (requestID + 5) % 29 == 0 || (requestID + 3) % 13 == 0 {
            postStr = postStr.replacingOccurrences(of: "\"method\":\"", with: "\"method\" : \"")
        } else {
            postStr = postStr.replacingOccurrences(of: "\"method\":\"", with: "\"method\": \"")
        }

        guard let postDataData = postStr.data(using: .utf8),
              let url = URL(string: kDeepLWebURL)
        else {
            completion(result, QueryError(type: .api, message: "Invalid request data"))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postDataData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let manager = AFURLSessionManager()
        manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval

        let startTime = CFAbsoluteTimeGetCurrent()

        let task = manager.dataTask(
            with: request,
            uploadProgress: nil,
            downloadProgress: nil
        ) { [weak self] _, responseObject, error in
            guard let self = self else { return }

            if queryModel.isServiceStopped(serviceType().rawValue) {
                return
            }

            if let nsError = error as? NSError, nsError.code == NSURLErrorCancelled {
                return
            }

            if let error = error {
                logError("deepLWebTranslate error: \(error)")
                var queryError = QueryError(type: .api, message: error.localizedDescription)

                // If web first and has auth key, try official API
                let useOfficialAPI = !Defaults[.deepLAuth].isEmpty &&
                    (Defaults[.deepLTranslation] == .webFirst)
                if useOfficialAPI {
                    deepLTranslate(text, from: from, to: to, completion: completion)
                    return
                }

                // Try to get error message from response data
                let nsError = error as NSError
                if let errorData = nsError.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? Data,
                   let json = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
                   let errorDict = json["error"] as? [String: Any],
                   let errorMessage = errorDict["message"] as? String {
                    queryError = QueryError(type: .api, message: nil, errorDataMessage: errorMessage)
                }

                completion(result, queryError)
                return
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            logInfo("deepLWebTranslate cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

            guard let responseData = responseObject as? Data else {
                // Try to parse as dictionary directly (AFNetworking may have already parsed it)
                if let responseDict = responseObject as? [String: Any] {
                    parseWebTranslateResponse(responseDict, completion: completion)
                    return
                }
                completion(result, QueryError(type: .api, message: "Invalid response"))
                return
            }

            do {
                if let responseDict = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                    parseWebTranslateResponse(responseDict, completion: completion)
                }
            } catch {
                completion(result, QueryError(type: .api, message: "Failed to parse response"))
            }
        }

        task.resume()

        queryModel.setStop({
            task.cancel()
        }, serviceType: serviceType().rawValue)
    }

    private func parseWebTranslateResponse(
        _ responseDict: [String: Any],
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
    ) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: responseDict)
            let response = try JSONDecoder().decode(DeepLTranslateResponse.self, from: jsonData)

            if let translatedText = response.result?.texts?.first?.text?.trim(), !translatedText.isEmpty {
                result.translatedResults = translatedText.toParagraphs()
                result.raw = responseDict as NSDictionary
            }
            completion(result, nil)
        } catch {
            completion(result, QueryError(type: .api, message: "Failed to decode response"))
        }
    }

    // MARK: - DeepL Official API Translate

    /// DeepL official API translate.
    /// Docs: https://www.deepl.com/zh/docs-api/translating-text
    func deepLTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, (any Error)?) -> ()
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

        let manager = AFHTTPSessionManager()
        manager.session.configuration.timeoutIntervalForRequest = EZNetWorkTimeoutInterval

        let authorization = "DeepL-Auth-Key \(authKey)"
        manager.requestSerializer.setValue(authorization, forHTTPHeaderField: "Authorization")

        let startTime = CFAbsoluteTimeGetCurrent()

        let task = manager.post(
            url,
            parameters: params,
            progress: nil,
            success: { [weak self] _, responseObject in
                guard let self = self else { return }

                let endTime = CFAbsoluteTimeGetCurrent()
                logInfo("deepLTranslate cost: \(String(format: "%.1f", (endTime - startTime) * 1000)) ms")

                if let responseDict = responseObject as? [String: Any] {
                    result.translatedResults = parseOfficialResponse(responseDict)
                    result.raw = responseDict as NSDictionary
                }
                completion(result, nil)
            },
            failure: { [weak self] _, error in
                guard let self = self else { return }

                if queryModel.isServiceStopped(serviceType().rawValue) {
                    return
                }

                if (error as NSError).code == NSURLErrorCancelled {
                    return
                }

                logError("deepLTranslate error: \(error)")

                // If official first, try web API
                if Defaults[.deepLTranslation] == .authKeyFirst {
                    deepLWebTranslate(text, from: from, to: to, completion: completion)
                    return
                }

                let queryError = QueryError(type: .api, message: error.localizedDescription)
                completion(result, queryError)
            }
        )

        queryModel.setStop({
            task?.cancel()
        }, serviceType: serviceType().rawValue)
    }

    private func parseOfficialResponse(_ responseDict: [String: Any]) -> [String]? {
        guard let translations = responseDict["translations"] as? [[String: Any]],
              let firstTranslation = translations.first,
              let translatedText = firstTranslation["text"] as? String
        else {
            return nil
        }
        return translatedText.toParagraphs()
    }

    // MARK: - Helper Methods

    private func getICount(_ text: String) -> Int {
        text.components(separatedBy: "i").count - 1
    }

    private func getRandomNumber() -> Int {
        let rand = Int.random(in: 100000 ... 189998)
        return rand * 1000
    }

    private func getTimestamp(iCount: Int) -> Int {
        let ts = Int(Date().timeIntervalSince1970 * 1000)
        if iCount != 0 {
            let count = iCount + 1
            return ts - (ts % count) + count
        } else {
            return ts
        }
    }
}

// MARK: - Dictionary Extension

extension [String: Any] {
    fileprivate func toJSONString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
