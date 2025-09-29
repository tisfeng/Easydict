//
//  DoubaoService.swift
//  Easydict
//
//  Created by Assistant on 2024/12/14.
//  Copyright © 2024 izual. All rights reserved.
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
            "model": "doubao-seed-translation-250915",
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

        let endpoint = "http://ark.cn-beijing.volces.com/api/v3/responses"

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
                    // 处理豆包返回的冗长响应，提取真正的翻译结果
                    let cleanedText = self?.extractTranslationFromDoubaoResponse(translatedText) ?? translatedText
                    result.translatedResults = [cleanedText]
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

    /// 从豆包的冗长响应中提取真正的翻译结果
    private func extractTranslationFromDoubaoResponse(_ response: String) -> String {
        // 豆包返回的响应包含很多解释性文字，我们需要提取出真正的翻译
        let lines = response.components(separatedBy: .newlines)

        // 寻找包含实际翻译的行
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // 跳过空行和解释性文字
            if trimmedLine.isEmpty ||
                trimmedLine.contains("请直接翻译") ||
                trimmedLine.contains("不需要任何解释") ||
                trimmedLine.contains("您好，我是") ||
                trimmedLine.contains("很高兴为您提供翻译") ||
                trimmedLine.contains("首先，我需要") ||
                trimmedLine.contains("翻译时需要") ||
                trimmedLine.contains("接下来") ||
                trimmedLine.contains("然后，考虑到") ||
                trimmedLine.contains("此外，还需要") ||
                trimmedLine.contains("最后，通读") ||
                trimmedLine.contains("总结来说") ||
                trimmedLine.hasPrefix("例如") ||
                trimmedLine.hasPrefix("因此") {
                continue
            }

            // 如果找到简短且没有解释性前缀的行，可能是翻译结果
            if trimmedLine.count < 50, !trimmedLine.contains("翻译"), !trimmedLine.contains("需要") {
                return trimmedLine
            }
        }

        // 如果没有找到简短的翻译，尝试查找引号中的内容
        let quotedPattern = #""([^"]+)""#
        if let regex = try? NSRegularExpression(pattern: quotedPattern) {
            let matches = regex.matches(in: response, range: NSRange(response.startIndex..., in: response))
            var candidates: [String] = []

            for match in matches {
                if let range = Range(match.range(at: 1), in: response) {
                    let quoted = String(response[range])
                    if quoted.count < 100 { // 确保不是长解释
                        candidates.append(quoted)
                    }
                }
            }

            // 优先选择中文翻译而不是原文
            for candidate in candidates {
                if candidate != "Hello world", candidate != "hello world" {
                    // 检查是否包含中文字符
                    if candidate.range(of: "[\u{4e00}-\u{9fff}]", options: .regularExpression) != nil {
                        return candidate
                    }
                }
            }

            // 如果没有中文，返回第一个候选
            if let first = candidates.first {
                return first
            }
        }

        // 如果都没找到，返回前100个字符作为fallback
        return String(response.prefix(100))
    }
}
