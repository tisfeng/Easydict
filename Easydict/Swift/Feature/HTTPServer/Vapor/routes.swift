//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

import MJExtension
import OpenAI
import SelectedTextKit
import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "Hello, Welcome to Easydict server!"
    }

    /// Translate text
    app.post("translate") { req async throws -> TranslationResponse in
        let request = try req.content.decode(TranslationRequest.self)
        let appleDictionaryNames = request.appleDictionaryNames

        guard let service = QueryServiceFactory.shared.service(withTypeId: request.serviceType) else {
            throw QueryError(
                type: .unsupportedServiceType, message: "\(request.serviceType)"
            )
        }

        if let appleDictionary = service as? AppleDictionary, let appleDictionaryNames {
            appleDictionary.appleDictionaryNames = appleDictionaryNames
        }

        // Reject `/translate` only when the current transport is actually streaming.
        // A stream-capable service may still route this request through a non-streaming
        // transport, so capability and transport must not be conflated here.
        if let streamService = service as? StreamService,
           streamService.usesStreamingTransport {
            let message =
                "\(request.serviceType) is stream service, which does not support 'translate'. Please use 'streamTranslate instead."
            throw QueryError(type: .api, message: message)
        }

        let result = try await service.translate(request: request)

        var response = TranslationResponse(
            translatedText: result.translatedText ?? "",
            sourceLanguage: result.from.code
        )

        // Decode word result to DictionaryEntry
        if let jsonData = result.wordResult?.mj_JSONData() {
            do {
                let decoder = JSONDecoder()
                let entry = try decoder.decode(DictionaryEntry.self, from: jsonData)
                response.dictionaryEntry = entry
            } catch {
                print("Decode DictionaryEntry failed: \(error)")
            }
        }

        if service is AppleDictionary {
            response.HTMLStrings = result.htmlStrings
        }

        return response
    }

    // Currently, streamTranslate only supports base OpenAI services.
    app.post("streamTranslate") { req async throws -> Response in
        let request = try req.content.decode(TranslationRequest.self)

        guard let service = QueryServiceFactory.shared.service(withTypeId: request.serviceType)
        else {
            throw QueryError(
                type: .unsupportedServiceType, message: "\(request.serviceType)"
            )
        }

        guard let streamService = service as? StreamService else {
            let message =
                "\(request.serviceType) is not stream service, which does not support 'streamTranslate'. Please use 'translate' instead."
            throw QueryError(type: .api, message: message)
        }

        let headers = HTTPHeaders([
            ("Content-Type", "text/event-stream"),
            ("Cache-Control", "no-cache"),
            ("Connection", "keep-alive"),
        ])

        let chatStream = try await streamService.streamTranslate(request: request)
        let jsonStream = chatStreamToJSONStream(chatStream: chatStream)

        let asyncBodyStream: @Sendable (AsyncBodyStreamWriter) async throws -> () = { writer in
            for await json in jsonStream {
                // SSE format https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using-server-sent_events
                let data = "data: \(json)\n\n"
                try await writer.write(.buffer(.init(string: data)))
            }
            try await writer.write(.end)
        }

        return Response(
            headers: headers,
            body: .init(asyncStream: asyncBodyStream)
        )
    }

    /// OCR image data up to 10MB. https://docs.vapor.codes/basics/routing/
    app.on(.POST, "ocr", body: .collect(maxSize: "10mb")) { req async throws -> OCRResponse in
        let request = try req.content.decode(OCRRequest.self)

        let queryModel = QueryModel()
        queryModel.ocrImage = NSImage(data: request.imageData)

        var from = Language.auto
        if let sourceLanguage = request.sourceLanguage {
            from = Language.language(fromCode: sourceLanguage)
        }
        queryModel.userSourceLanguage = from

        let detectManager = DetectManager(model: queryModel)
        let result = try await detectManager.ocr()

        return OCRResponse(
            ocrText: result.mergedText,
            sourceLanguage: result.from.code
        )
    }

    /// Detect language
    app.post("detect") { req async throws -> DetectResponse in
        let request = try req.content.decode(DetectRequest.self)
        let queryModel = try await DetectManager().detectText(request.text)

        return DetectResponse(sourceLanguage: queryModel.detectedLanguage.code)
    }

    /// Get selected text
    app.get("selectedText") { _ async throws -> GetSelectedTextResponse in
        let selectedText = try await SelectedTextManager.shared.getSelectedText(strategy: .auto)
        return GetSelectedTextResponse(selectedText: selectedText)
    }
}

/// Convert chat stream to a JSON stream, wrapping any error as a JSON message.
private func chatStreamToJSONStream(
    chatStream: AsyncThrowingStream<ChatStreamResult, Error>
) -> AsyncStream<String> {
    AsyncStream<String> { continuation in
        Task {
            defer { continuation.finish() }
            do {
                for try await chatResult in chatStream {
                    if let json = chatResult.jsonString {
                        continuation.yield(json)
                    }
                }
            } catch {
                if let errorJson = makeJSONErrorMessage(error) {
                    continuation.yield(errorJson)
                }
            }
        }
    }
}

private func makeJSONErrorMessage(_ error: Error) -> String? {
    let queryError = QueryError.queryError(from: error)
    let errorMessage = queryError?.localizedDescription ?? error.localizedDescription
    let errorDict = ["error": errorMessage]
    guard let errorData = try? JSONSerialization.data(withJSONObject: errorDict) else {
        return nil
    }
    return String(data: errorData, encoding: .utf8)
}
