//
//  DoubaoService.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

@objc(EZDoubaoService)
public final class DoubaoService: QueryService {
    // MARK: Public

    public override func serviceType() -> ServiceType {
        .doubao
    }

    public override func link() -> String? {
        "https://www.volcengine.com/product/doubao"
    }

    public override func name() -> String {
        NSLocalizedString("doubao_translate", comment: "The name of Doubao Translate")
    }

    public override func supportLanguagesDictionary() -> MMOrderedDictionary<AnyObject, AnyObject> {
        DoubaoTranslateType.supportLanguagesDictionary.toMMOrderedDictionary()
    }

    public override func needPrivateAPIKey() -> Bool {
        true
    }

    public override func hasPrivateAPIKey() -> Bool {
        !apiKey.isEmpty
    }

    /// Doubao Translation API
    override public func translate(
        _ text: String,
        from: Language,
        to: Language,
        completion: @escaping (EZQueryResult, Error?) -> ()
    ) {
        let result = result

        // Validate API key
        if let error = validateAPIKey() {
            completion(result, error)
            return
        }

        let transType = DoubaoTranslateType.transType(from: from, to: to)
        guard transType != .unsupported else {
            let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
            let showingTo = EZLanguageManager.shared().showingLanguageName(to)
            let error = QueryError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
            completion(result, error)
            return
        }

        // Prepare request body according to Doubao API format
        let requestBody: [String: Any] = [
            "model": model,
            "input": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "input_text",
                            "text": "\(text)",
                            "translation_options": [
                                "source_language": transType.sourceLanguage,
                                "target_language": transType.targetLanguage,
                            ],
                        ],
                    ],
                ],
            ],
        ]

        let endpoint = "https://ark.cn-beijing.volces.com/api/v3/responses"

        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
        ]

        if !apiKey.isEmpty {
            headers["Authorization"] = "Bearer \(apiKey)"
        }

        let request = AF.request(
            endpoint,
            method: .post,
            parameters: requestBody,
            encoding: JSONEncoding.default,
            headers: headers
        )
        .validate()
        .responseDecodable(of: DoubaoResponse.self) { [weak self] response in
            guard self != nil else { return }

            switch response.result {
            case let .success(doubaoResponse):
                if let error = doubaoResponse.error {
                    let errorMessage = error.message ?? "Unknown error"
                    logError("Doubao translate error: \(errorMessage)")
                    let queryError = QueryError(type: .api, message: errorMessage)
                    completion(result, queryError)
                } else if let outputs = doubaoResponse.output,
                          let firstOutput = outputs.first,
                          let content = firstOutput.content,
                          let firstContent = content.first,
                          let translatedText = firstContent.text {
                    result.translatedResults = [translatedText]
                    completion(result, nil)
                } else {
                    let errorMessage = "Unexpected response format"
                    logError("Doubao translate error: \(errorMessage)")
                    let queryError = QueryError(type: .unknown, message: errorMessage)
                    completion(result, queryError)
                }

            case let .failure(error):
                logError("Doubao translate error: \(error)")

                let errorMessage = error.localizedDescription
                let queryError = QueryError(type: .api, message: errorMessage)

                if let data = response.data {
                    do {
                        let errorResponse = try JSONDecoder().decode(
                            DoubaoResponse.self, from: data
                        )
                        if let doubaoError = errorResponse.error {
                            queryError.errorDataMessage = doubaoError.message
                        }
                    } catch {
                        logError("Failed to decode error response: \(error)")
                    }
                }
                completion(result, queryError)
            }
        }

        queryModel.setStop({
            request.cancel()
        }, serviceType: serviceType().rawValue)
    }

    // MARK: Private

    /// easydict://writeKeyValue?EZDoubaoAPIKey=xxx
    private var apiKey: String {
        Defaults[.doubaoAPIKey]
    }

    /// easydict://writeKeyValue?EZDoubaoModelKey=xxx
    private var model: String {
        let value = Defaults[.doubaoModel].trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "doubao-seed-translation-250915" : value
    }

    /// Validates the API key, returns a QueryError if missing
    private func validateAPIKey() -> QueryError? {
        if apiKey.isEmpty {
            return QueryError(
                type: .missingSecretKey,
                message: "Missing Doubao API Key. Get your API key from https://www.volcengine.com/product/doubao"
            )
        }
        return nil
    }
}
