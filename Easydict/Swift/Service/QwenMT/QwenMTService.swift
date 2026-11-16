//
//  QwenMTService.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Foundation
import OpenAI

// MARK: - QwenMTService

/// Uses Qwen-MT's translation options instead of chat prompts.
@objc(EZQwenMTService)
class QwenMTService: StreamService {
    // MARK: Public

    public override func name() -> String {
        String(localized: "service.qwen_mt.name")
    }

    public override func serviceType() -> ServiceType {
        .qwenMT
    }

    public override func link() -> String? {
        "https://help.aliyun.com/zh/model-studio/machine-translation"
    }

    public override func supportedQueryType() -> EZQueryTextType {
        .translation
    }

    public override func supportLanguagesDictionary() -> MMOrderedDictionary {
        makeLanguageDictionary()
    }

    public override func configurationListItems() -> Any? {
        StreamConfigurationView(
            service: self,
            showCustomPromptSection: false,
            showTranslationToggle: false,
            showSentenceToggle: false,
            showDictionaryToggle: false,
            showThinkTagContent: false
        )
    }

    public override func cancelStream() {
        taskControl.cancel()
    }

    // MARK: Internal

    override var defaultModels: [String] {
        ["qwen-mt-flash", "qwen-mt-plus", "qwen-mt-lite"]
    }

    override var defaultEndpoint: String {
        "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    }

    override var usesStreamingTransport: Bool {
        model.hasPrefix("qwen-mt-flash") || model.hasPrefix("qwen-mt-lite")
    }

    override func contentStreamTranslate(
        _ text: String,
        from: Language,
        to: Language
    )
        -> AsyncThrowingStream<String, Error> {
        let taskControl = taskControl
        return AsyncThrowingStream { continuation in
            let identifier = UUID()
            taskControl.begin(identifier: identifier)

            let task = Task {
                defer { taskControl.finish(identifier: identifier) }
                do {
                    try Task.checkCancellation()
                    let body = try translationRequest(text: text, from: from, to: to, model: model)
                    let request = try urlRequest(body: body)
                    if body.stream {
                        _ = try await OpenAIStreamTransport().stream(request: request) { result in
                            if let content = result.choices.first?.delta.content {
                                continuation.yield(content)
                            }
                        }
                    } else {
                        continuation.yield(try await requestTranslation(request))
                    }
                    try Task.checkCancellation()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Task.isCancelled ? CancellationError() : error)
                }
            }

            taskControl.install(task, identifier: identifier)
            continuation.onTermination = { _ in
                taskControl.cancel(identifier: identifier)
            }
        }
    }

    /// Builds the provider payload without adding dictionary, sentence, or system prompts.
    @nonobjc
    func translationRequest(
        text: String, from: Language, to: Language, model: String
    ) throws
        -> QwenMTTranslationRequest {
        guard let source = translationLanguageCode(for: from, model: model) else {
            throw QueryError(type: .unsupportedLanguage, message: from.localizedName)
        }
        guard to != .auto, let target = translationLanguageCode(for: to, model: model) else {
            throw QueryError(type: .unsupportedLanguage, message: to.localizedName)
        }

        return QwenMTTranslationRequest(
            model: model,
            messages: [.init(role: "user", content: text)],
            translationOptions: .init(sourceLanguage: source, targetLanguage: target)
        )
    }

    // MARK: Private

    private let taskControl = OpenAIStreamTaskControl()

    private func urlRequest(body: QwenMTTranslationRequest) throws -> URLRequest {
        guard let url = URL(string: endpoint.trim()), url.isValid else {
            throw QueryError(type: .parameter)
        }
        guard !apiKey.trim().isEmpty else {
            throw QueryError(type: .missingSecretKey)
        }

        var request = URLRequest(url: url, timeoutInterval: AppConstants.llmRequestTimeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(body.stream ? "text/event-stream" : "application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(apiKey.trim())", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func requestTranslation(_ request: URLRequest) async throws -> String {
        let response = await AF.request(request)
            .serializingData(automaticallyCancelling: true)
            .response
        try Task.checkCancellation()

        if let statusCode = response.response?.statusCode, !(200 ... 299).contains(statusCode) {
            if let data = response.data,
               let error = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw error
            }
            throw QueryError(
                type: .api,
                message: "HTTP \(statusCode)",
                errorDataMessage: response.data.flatMap { String(data: $0, encoding: .utf8) }
            )
        }

        let data = try response.result.get()
        let result = try JSONDecoder().decode(ChatResult.self, from: data)
        guard let content = result.choices.first?.message.content, !content.trim().isEmpty else {
            throw QueryError(type: .noResult)
        }
        return content
    }
}

// MARK: - QwenMTTranslationRequest

/// The OpenAI-compatible Qwen-MT payload has exactly one user message.
struct QwenMTTranslationRequest: Encodable {
    // MARK: Internal

    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct TranslationOptions: Encodable {
        // MARK: Internal

        let sourceLanguage: String
        let targetLanguage: String

        // MARK: Private

        private enum CodingKeys: String, CodingKey {
            case sourceLanguage = "source_lang"
            case targetLanguage = "target_lang"
        }
    }

    let model: String
    let messages: [Message]
    let translationOptions: TranslationOptions

    /// Plus returns cumulative chunks, so it uses a complete JSON response.
    var stream: Bool {
        model.hasPrefix("qwen-mt-flash") || model.hasPrefix("qwen-mt-lite")
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(model, forKey: .model)
        try container.encode(messages, forKey: .messages)
        try container.encode(stream, forKey: .stream)
        try container.encode(translationOptions, forKey: .translationOptions)
    }

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case model, messages, stream
        case translationOptions = "translation_options"
    }
}
