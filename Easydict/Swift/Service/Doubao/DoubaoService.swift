//
//  DoubaoService.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZDoubaoService)
public final class DoubaoService: StreamService {
    // MARK: Public

    /// Default Doubao translation model identifier
    public static let defaultModelIdentifier = "doubao-seed-translation-250915"

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

    // MARK: Internal

    override var defaultModels: [String] {
        [Self.defaultModelIdentifier]
    }

    override var defaultModel: String {
        Self.defaultModelIdentifier
    }

    /// Stream-based content translation for Doubao API
    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            // Validate API key
            if let error = validateAPIKey() {
                continuation.finish(throwing: error)
                return
            }

            let transType = DoubaoTranslateType.transType(from: from, to: to)
            guard transType != .unsupported else {
                let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
                let showingTo = EZLanguageManager.shared().showingLanguageName(to)
                let error = QueryError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
                continuation.finish(throwing: error)
                return
            }

            currentTask = Task {
                do {
                    // Prepare request body
                    let requestBody: [String: Any] = [
                        "model": model,
                        "stream": true,
                        "input": [
                            [
                                "role": "user",
                                "content": [
                                    [
                                        "type": "input_text",
                                        "text": text,
                                        "translation_options": [
                                            "source_language": transType.sourceLanguage,
                                            "target_language": transType.targetLanguage,
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ]

                    let endpoint = URL(string: "https://ark.cn-beijing.volces.com/api/v3/responses")!

                    var urlRequest = URLRequest(url: endpoint)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                    // Note: We use URLSession.shared.bytes instead of ChatQuery/Gemini-style requests because:
                    // 1. Doubao provides a specialized translation API, not a general chat/LLM API
                    // 2. The API uses a unique format with "translation_options" parameter, which is incompatible with
                    //    standard chat message formats (system/user/assistant roles)
                    // 3. Similar to traditional translation services (Youdao, Ali, Tencent), we directly construct
                    //    HTTP requests to match the provider's API specification
                    // 4. Unlike OpenAI/Gemini which use conversational prompts, Doubao's translation model expects
                    //    structured input with explicit source/target language parameters
                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: urlRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw QueryError(
                            type: .api,
                            message: NSLocalizedString(
                                "doubao.error.invalid_response",
                                comment: ""
                            )
                        )
                    }

                    guard (200 ... 299).contains(httpResponse.statusCode) else {
                        let errorMessage = String(
                            format: NSLocalizedString(
                                "doubao.error.http_error",
                                comment: ""
                            ),
                            httpResponse.statusCode
                        )
                        throw QueryError(type: .api, message: errorMessage)
                    }

                    var dataBuffer = Data()
                    var textBuffer = ""

                    for try await byte in asyncBytes {
                        // Check for cancellation
                        try Task.checkCancellation()

                        dataBuffer.append(byte)

                        // Try to decode accumulated bytes as UTF-8
                        if let text = String(data: dataBuffer, encoding: .utf8) {
                            textBuffer.append(text)
                            dataBuffer.removeAll()

                            // Process complete SSE events
                            if textBuffer.contains("\n\n") {
                                let events = textBuffer.components(separatedBy: "\n\n")
                                textBuffer = events.last ?? ""

                                for event in events.dropLast() {
                                    if let content = parseSSEEvent(event) {
                                        continuation.yield(content)
                                    }
                                }
                            }
                        }
                        // If decoding fails, continue accumulating bytes (incomplete UTF-8 sequence)
                    }

                    continuation.finish()
                } catch is CancellationError {
                    logInfo("Doubao task was cancelled.")
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    override func cancelStream() {
        currentTask?.cancel()
    }

    // MARK: Private

    private var currentTask: Task<(), Never>?

    /// SSE event type for translation delta updates
    private let deltaEventType = "response.output_text.delta"

    /// Validates the API key, returns a QueryError if missing
    private func validateAPIKey() -> QueryError? {
        guard !apiKey.isEmpty else {
            return QueryError(
                type: .missingSecretKey,
                message: NSLocalizedString(
                    "doubao.error.missing_api_key",
                    comment: ""
                )
            )
        }
        return nil
    }

    /// Parse SSE event and extract delta content
    /// Doubao API returns SSE events in the format:
    /// event: response.output_text.delta
    /// data: {"type":"response.output_text.delta","delta":"text"}
    private func parseSSEEvent(_ event: String) -> String? {
        let lines = event.components(separatedBy: "\n")
        var eventType = ""
        var data = ""

        for line in lines {
            if line.hasPrefix("event: ") {
                eventType = String(line.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("data: ") {
                data = String(line.dropFirst(6))
            }
        }

        // Only process output_text.delta events
        guard eventType == deltaEventType, data != "[DONE]" else {
            return nil
        }

        // Parse JSON data and extract delta
        guard let jsonData = data.data(using: .utf8),
              let streamEvent = try? JSONDecoder().decode(DoubaoStreamEvent.self, from: jsonData),
              let delta = streamEvent.delta else {
            return nil
        }

        return delta
    }
}
