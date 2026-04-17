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

private let kDeepLWebURL = "https://www2.deepl.com/jsonrpc"

// MARK: - DeepLService + Translate

extension DeepLService {
    // MARK: - Web Translate

    /// DeepL web translate.
    /// Ref: https://github.com/akl7777777/bob-plugin-akl-deepl-free-translate/blob/9d194783b3eb8b3a82f21bcfbbaf29d6b28c2761/src/main.js
    func deepLWebTranslate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (QueryResult, (any Error)?) -> ()
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
        request.timeoutInterval = EZNetWorkTimeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let startTime = CFAbsoluteTimeGetCurrent()

        let dataRequest = AF.request(request)
            .validate(statusCode: 200 ..< 300)

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

            guard let responseData = response.data else {
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

        queryModel.setStop({
            dataRequest.cancel()
        }, serviceType: serviceType().rawValue)
    }

    // MARK: - Web Translate Response Parser

    private func parseWebTranslateResponse(
        _ responseDict: [String: Any],
        completion: @escaping (QueryResult, (any Error)?) -> ()
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

    private func parseOfficialResponse(_ responseDict: [String: Any]) -> [String]? {
        guard let translations = responseDict["translations"] as? [[String: Any]],
              let firstTranslation = translations.first,
              let translatedText = firstTranslation["text"] as? String
        else {
            return nil
        }
        return translatedText.toParagraphs()
    }

    private func parseDeepLErrorMessage(from data: Data?) -> String? {
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let errorDict = json["error"] as? [String: Any],
              let errorMessage = errorDict["message"] as? String
        else {
            return nil
        }
        return errorMessage
    }

    // MARK: - Request Helper Methods

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
