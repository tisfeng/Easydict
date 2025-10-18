//
//  DoubaoService.swift
//  Easydict
//
//  Created by Liaoworking on 2025/9/30.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

/**
 The specifically designed Doubao AI Model for translation.
 Documentation: https://www.volcengine.com/docs/82379/1820188
 API Key Application: https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey
 */

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
                continuation.finish(throwing: createUnsupportedLanguageError(from: from, to: to))
                return
            }

            currentTask = Task {
                do {
                    let requestBody = buildRequestBody(text: text, transType: transType)
                    let urlRequest = try createURLRequest(body: requestBody)

                    let (asyncBytes, response) = try await URLSession.shared.bytes(for: urlRequest)
                    try validateHTTPResponse(response)

                    try await processStreamBytes(asyncBytes, continuation: continuation)
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

    /// Creates an error for unsupported language pairs
    /// - Parameters:
    ///   - from: The source language
    ///   - to: The target language
    /// - Returns: A QueryError with unsupported language message
    private func createUnsupportedLanguageError(from: Language, to: Language) -> QueryError {
        let showingFrom = EZLanguageManager.shared().showingLanguageName(from)
        let showingTo = EZLanguageManager.shared().showingLanguageName(to)
        return QueryError(type: .unsupportedLanguage, message: "\(showingFrom) --> \(showingTo)")
    }

    /// Builds the request body for Doubao translation API
    /// - Parameters:
    ///   - text: The text to be translated
    ///   - transType: The translation type containing source and target language codes
    /// - Returns: A dictionary containing the formatted request body for the API
    private func buildRequestBody(text: String, transType: DoubaoTranslateType) -> [String: Any] {
        [
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
    }

    /// Creates and configures URLRequest for Doubao API
    ///
    /// Note: We use URLSession.shared.bytes instead of ChatQuery/Gemini-style requests because:
    /// 1. Doubao provides a specialized translation API, not a general chat/LLM API
    /// 2. The API uses a unique format with "translation_options" parameter, which is incompatible with
    ///    standard chat message formats (system/user/assistant roles)
    /// 3. Similar to traditional translation services (Youdao, Ali, Tencent), we directly construct
    ///    HTTP requests to match the provider's API specification
    /// 4. Unlike OpenAI/Gemini which use conversational prompts, Doubao's translation model expects
    ///    structured input with explicit source/target language parameters
    ///
    /// - Parameter body: The request body dictionary to be serialized as JSON
    /// - Returns: A configured URLRequest with authorization headers and JSON body
    /// - Throws: An error if JSON serialization fails
    private func createURLRequest(body: [String: Any]) throws -> URLRequest {
        let endpoint = URL(string: "https://ark.cn-beijing.volces.com/api/v3/responses")!

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        return urlRequest
    }

    /// Validates HTTP response status
    /// - Parameter response: The URLResponse to validate
    /// - Throws: QueryError if response is not HTTPURLResponse or status code is not in 200-299 range
    private func validateHTTPResponse(_ response: URLResponse) throws {
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
    }

    /// Processes stream bytes and yields translation content
    /// - Parameters:
    ///   - asyncBytes: The async byte stream from URLSession
    ///   - continuation: The continuation to yield translated content chunks
    /// - Throws: CancellationError if task is cancelled, or other errors during processing
    private func processStreamBytes(
        _ asyncBytes: URLSession.AsyncBytes,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        var dataBuffer = Data()
        var textBuffer = ""
        let bufferThreshold = 1024 // Process in 1KB chunks for better performance

        for try await byte in asyncBytes {
            // Check for cancellation
            try Task.checkCancellation()

            dataBuffer.append(byte)

            // Process bytes in larger chunks to improve performance
            // Only attempt decoding when we have enough bytes or detect event boundary
            guard dataBuffer.count >= bufferThreshold || byte == 0x0A else { // 0x0A is '\n'
                continue
            }

            // Try to decode accumulated bytes as UTF-8
            if let text = String(data: dataBuffer, encoding: .utf8) {
                textBuffer.append(text)
                dataBuffer.removeAll()

                // Process complete SSE events
                processCompleteEvents(from: &textBuffer, continuation: continuation)
            }
            // If decoding fails, continue accumulating bytes (incomplete UTF-8 sequence)
        }

        // Process any remaining data in the buffer
        if !dataBuffer.isEmpty, let text = String(data: dataBuffer, encoding: .utf8) {
            textBuffer.append(text)
        }

        // Process any remaining complete events
        processCompleteEvents(from: &textBuffer, continuation: continuation)
    }

    /// Processes complete SSE events from the text buffer
    /// - Parameters:
    ///   - textBuffer: The text buffer containing SSE events, modified in-place to keep remaining incomplete events
    ///   - continuation: The continuation to yield parsed translation content
    private func processCompleteEvents(
        from textBuffer: inout String,
        continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        guard textBuffer.contains("\n\n") else { return }

        let events = textBuffer.components(separatedBy: "\n\n")
        textBuffer = events.last ?? ""

        for event in events.dropLast() where !event.isEmpty {
            if let content = parseSSEEvent(event) {
                continuation.yield(content)
            }
        }
    }

    /// Parse SSE event and extract delta content
    ///
    /// Doubao API returns SSE events in the format:
    /// ```
    /// event: response.output_text.delta
    /// data: {"type":"response.output_text.delta","delta":"text"}
    /// ```
    /// - Parameter event: The SSE event string to parse
    /// - Returns: The delta text content if the event is a valid translation delta, nil otherwise
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
