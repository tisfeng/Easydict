//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

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
        if let entry = DictionaryEntry(wordResult: result.wordResult) {
            response.dictionaryEntry = entry
        }

        if service is AppleDictionary {
            response.HTMLStrings = result.htmlStrings
        }

        let queryModel = result.queryModel
        let text = queryModel.queryText
        let shouldRecord = !service.isStream() || result.isStreamFinished
        let hasContent = !text.isEmpty
            && (result.wordResult != nil || !(result.translatedText ?? "").isEmpty)
        if shouldRecord, hasContent, result.error == nil {
            VocabularyNotebookService.shared.append(queryModel: queryModel, result: result)
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
        let fallbackModel = streamService.model

        let asyncBodyStream: @Sendable (AsyncBodyStreamWriter) async throws -> () = { writer in
            var accumulatedText = ""
            var streamError: Error?
            do {
                for try await chatResult in chatStream {
                    if let content = chatResult.content {
                        accumulatedText += content
                    }
                    if let json = chatResult.jsonString {
                        // SSE format https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using-server-sent_events
                        let data = "data: \(json)\n\n"
                        try await writer.write(.buffer(.init(string: data)))
                    }
                }
            } catch {
                streamError = error
                if let errorJson = makeJSONErrorMessage(error, fallbackModel: fallbackModel) {
                    let data = "data: \(errorJson)\n\n"
                    try await writer.write(.buffer(.init(string: data)))
                }
            }

            // Record the vocabulary entry after the stream finishes. The HTTP stream
            // path never populates `streamService.result.translatedResults`, so backfill
            // it from the accumulated chunks before appending. A stream error leaves
            // `result.error` unset, so it must be gated separately to avoid recording an
            // incomplete translation.
            if streamError == nil, let result = streamService.result {
                let shouldRecord = !streamService.isStream() || result.isStreamFinished
                let hasContent = !accumulatedText.isEmpty
                if shouldRecord, hasContent, result.error == nil {
                    result.translatedResults = accumulatedText
                        .split(separator: "\n", omittingEmptySubsequences: false)
                        .map(String.init)
                    VocabularyNotebookService.shared.append(
                        queryModel: result.queryModel,
                        result: result
                    )
                }
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

private func makeJSONErrorMessage(_ error: Error, fallbackModel: String) -> String? {
    let queryError = QueryError.queryError(from: error)
    let errorMessage = queryError?.localizedDescription ?? error.localizedDescription

    guard let chatStreamResult = try? ChatStreamResult.create(
        content: errorMessage,
        model: fallbackModel
    ),
        let chunkData = chatStreamResult.jsonData,
        var errorDict = try? JSONSerialization.jsonObject(with: chunkData) as? [String: Any]
    else {
        return nil
    }

    errorDict["error"] = errorMessage
    guard let errorData = try? JSONSerialization.data(withJSONObject: errorDict) else {
        return nil
    }
    return String(data: errorData, encoding: .utf8)
}
