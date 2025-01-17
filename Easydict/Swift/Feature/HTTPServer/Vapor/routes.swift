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

        guard let service = ServiceTypes.shared().service(withTypeId: request.serviceType) else {
            throw QueryError(
                type: .unsupportedServiceType, message: "\(request.serviceType)"
            )
        }

        if let appleDictionary = service as? AppleDictionary, let appleDictionaryNames {
            appleDictionary.appleDictionaryNames = appleDictionaryNames
        }

        if service.isStream() {
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

        guard let service = ServiceTypes.shared().service(withTypeId: request.serviceType)
        else {
            throw QueryError(
                type: .unsupportedServiceType, message: "\(request.serviceType)"
            )
        }

        guard let streamService = service as? LLMStreamService else {
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
        let jsonStream = try await chatStreamToJSONStream(chatStream: chatStream)

        let asyncBodyStream: @Sendable (AsyncBodyStreamWriter) async throws -> () = { writer in
            do {
                for try await json in jsonStream {
                    // SSE format https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events
                    let data = "data: \(json)\n\n"
                    try await writer.write(.buffer(.init(string: data)))
                }
                try await writer.write(.end)
            } catch {
                if let queryError = QueryError.queryError(from: error) {
                    let errorData = "data: \(queryError.localizedDescription)\n\n"
                    try await writer.write(.buffer(.init(string: errorData)))
                }
            }
        }

        return Response(
            headers: headers,
            body: .init(asyncStream: asyncBodyStream)
        )
    }

    /// OCR image data up to 10MB. https://docs.vapor.codes/basics/routing/
    app.on(.POST, "ocr", body: .collect(maxSize: "10mb")) { req async throws -> OCRResponse in
        let request = try req.content.decode(OCRRequest.self)

        let queryModel = EZQueryModel()
        queryModel.ocrImage = NSImage(data: request.imageData)

        var from = Language.auto
        if let sourceLanguage = request.sourceLanguage {
            from = Language.language(fromCode: sourceLanguage)
        }
        queryModel.userSourceLanguage = from

        let detectManager = EZDetectManager(model: queryModel)
        let result = try await detectManager.ocr()

        return OCRResponse(
            ocrText: result.mergedText,
            sourceLanguage: result.from.code
        )
    }

    /// Detect language
    app.post("detect") { req async throws -> DetectResponse in
        let request = try req.content.decode(DetectRequest.self)
        let queryModel = try await EZDetectManager().detectText(request.text)

        return DetectResponse(sourceLanguage: queryModel.detectedLanguage.code)
    }

    /// Get selected text
    app.get("selectedText") { _ async throws -> GetSelectedTextResponse in
        let selectedText = try await getSelectedText()
        return GetSelectedTextResponse(selectedText: selectedText)
    }
}

/// Convert chat stream to json stream
func chatStreamToJSONStream(chatStream: AsyncThrowingStream<ChatStreamResult, Error>) async throws
    -> AsyncThrowingStream<String, Error> {
    var json: String?

    // Check first element for potential errors
    var iterator = chatStream.makeAsyncIterator()
    if let firstResult = try await iterator.next() {
        json = firstResult.jsonString
    }

    return AsyncThrowingStream<String, Error> { continuation in
        continuation.yield(json ?? "")

        Task {
            do {
                for try await chatResult in chatStream {
                    if let json = chatResult.jsonString {
                        continuation.yield(json)
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
