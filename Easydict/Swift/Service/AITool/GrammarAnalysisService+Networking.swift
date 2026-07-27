//
//  GrammarAnalysisService+Networking.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/7.
//

import Foundation

// MARK: - GrammarAnalysisGateDecision

/// Captures the low-cost worthiness decision before full analysis.
struct GrammarAnalysisGateDecision: Decodable {
    let shouldAnalyze: Bool
    let reason: String?
}

// MARK: - GrammarAnalysisChatCompletionRequest

/// Encodes a minimal non-streaming chat-completions request payload.
struct GrammarAnalysisChatCompletionRequest: Encodable {
    let model: String
    let messages: [GrammarAnalysisChatPayloadMessage]
    let temperature: Double
    let stream: Bool
}

// MARK: - GrammarAnalysisChatPayloadMessage

/// Represents one chat message in an OpenAI-compatible request body.
struct GrammarAnalysisChatPayloadMessage: Encodable {
    let role: String
    let content: String
}

// MARK: - GrammarAnalysisChatCompletionResponse

/// Decodes only the response fields needed to extract assistant text.
struct GrammarAnalysisChatCompletionResponse: Decodable {
    /// Wraps one returned completion choice.
    struct Choice: Decodable {
        let message: Message
    }

    /// Stores the assistant message body for one completion choice.
    struct Message: Decodable {
        // MARK: Lifecycle

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.content = try container.decode(Content.self, forKey: .content)
        }

        // MARK: Internal

        enum CodingKeys: String, CodingKey {
            case content
        }

        let content: Content
    }

    /// Normalizes string and array-based provider content into plain text.
    struct Content: Decodable {
        // MARK: Lifecycle

        init(from decoder: Decoder) throws {
            let singleValueContainer = try decoder.singleValueContainer()
            if let string = try? singleValueContainer.decode(String.self) {
                self.text = string
                return
            }

            let parts = try singleValueContainer.decode([ContentPart].self)
            self.text = parts.compactMap(\.text).joined()
        }

        // MARK: Internal

        let text: String
    }

    /// Decodes one text fragment from array-based content payloads.
    struct ContentPart: Decodable {
        let text: String?
    }

    let choices: [Choice]
}

// MARK: - GrammarAnalysisChatCompletionErrorResponse

/// Decodes provider-side error messages for non-2xx responses.
struct GrammarAnalysisChatCompletionErrorResponse: Decodable {
    /// Holds the provider's human-readable error message.
    struct ProviderError: Decodable {
        let message: String?
    }

    let error: ProviderError
}

extension GrammarAnalysisService {
    func fetchGateDecision(for text: String) async throws -> GrammarAnalysisGateDecision {
        let systemPrompt = """
        You decide whether a dictionary app should run grammar analysis for a \
        text input.
        Analyze value, not user intent. Grammar analysis is worthwhile only \
        when the input is a natural-language sentence, clause, or multi-word \
        expression with real syntactic structure.
        Long instructions, procedural text, or explanatory paragraphs with \
        clear clause relationships are still analyzable natural language and \
        should not be rejected merely because they are commands or workflow \
        descriptions.

        Skip inputs such as:
        - single words or simple greetings
        - filenames or screenshot titles
        - URLs, IDs, timestamps, menu labels, code symbols
        - random fragments with no meaningful grammar to explain

        Return JSON only with this schema:
        {"shouldAnalyze":true,"reason":"short reason"}
        """

        let userPrompt = """
        Text:
        \"\"\"\(text)\"\"\"
        """

        let response = try await requestChatCompletion(
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt),
            ],
            model: gateModel,
            temperature: 0
        )

        let cleanedResponse = cleanJSONResponse(response)
        guard let data = cleanedResponse.data(using: .utf8),
              let decision = try? JSONDecoder().decode(
                  GrammarAnalysisGateDecision.self,
                  from: data
              )
        else {
            return GrammarAnalysisGateDecision(shouldAnalyze: true, reason: nil)
        }

        return decision
    }

    func requestChatCompletion(
        messages: [GrammarAnalysisChatPayloadMessage],
        model: String,
        temperature: Double
    ) async throws
        -> String {
        let trimmedModel = model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedModel.isEmpty else {
            throw QueryError(
                type: .parameter,
                message: String(localized: "grammar.analysis.missing_model")
            )
        }

        guard let url = URL(string: endpoint), url.isValid else {
            throw QueryError(
                type: .parameter,
                message: "`\(serviceType().rawValue)` endpoint is invalid"
            )
        }

        if apiKeyRequirement().requiresKeyForRequest, apiKey.trim().isEmpty {
            throw QueryError(type: .missingSecretKey, message: "API key is empty")
        }

        let requestBody = GrammarAnalysisChatCompletionRequest(
            model: trimmedModel,
            messages: messages,
            temperature: temperature,
            stream: false
        )

        var request = URLRequest(
            url: url,
            timeoutInterval: EZNetWorkTimeoutInterval
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue(apiKey, forHTTPHeaderField: "api-key")
        }
        request.httpBody = try JSONEncoder().encode(requestBody)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            try Task.checkCancellation()
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession may surface Stop-triggered cancellation as URLError.
            throw CancellationError()
        } catch let nsError as NSError
            where nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200 ... 299).contains(httpResponse.statusCode) {
            let providerError = try? JSONDecoder().decode(
                GrammarAnalysisChatCompletionErrorResponse.self,
                from: data
            )
            throw QueryError(
                type: .api,
                message: providerError?.error.message ??
                    "HTTP \(httpResponse.statusCode)",
                errorDataMessage: String(data: data, encoding: .utf8)
            )
        }

        let completion = try JSONDecoder().decode(
            GrammarAnalysisChatCompletionResponse.self,
            from: data
        )
        guard let text = completion.choices.first?.message.content.text
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else {
            throw QueryError(type: .noResult)
        }

        return text
    }

    func cleanJSONResponse(_ response: String) -> String {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```") else {
            return trimmed
        }

        let lines = trimmed.components(separatedBy: .newlines)
        let cleanedLines = lines.filter { line in
            !line.hasPrefix("```")
        }
        return cleanedLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cleanMarkdownResponse(_ response: String) -> String {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("```"), trimmed.hasSuffix("```") else {
            return trimmed
        }

        let lines = trimmed.components(separatedBy: .newlines)
        guard lines.count >= 2 else {
            return trimmed
        }

        let openingLine = lines[0]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let closingLine = lines[lines.count - 1]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let isMarkdownFence = ["```", "```markdown", "```md"].contains(openingLine)
        guard isMarkdownFence, closingLine == "```" else {
            return trimmed
        }

        return lines
            .dropFirst()
            .dropLast()
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
