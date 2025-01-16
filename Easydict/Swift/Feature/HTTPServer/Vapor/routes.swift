//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

import MJExtension
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

        guard let service = ServiceTypes.shared().service(withTypeId: request.serviceType) else {
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

        return Response(
            headers: headers,
            body: .init(asyncStream: { writer in
                do {
                    let chatStreamResults = try await streamService.streamTranslate(
                        request: request
                    )
                    for try await streamResult in chatStreamResults {
                        if let json = streamResult.jsonString {
                            let event = "data: \(json)\n\n"
                            try await writer.write(.buffer(.init(string: event)))
                        }
                    }
                } catch {
                    if let queryError = QueryError.queryError(from: error) {
                        let errorEvent = "data: \(queryError.localizedDescription)\n\n"
                        try await writer.write(.buffer(.init(string: errorEvent)))
                    }
                }
                try await writer.write(.end)
            })
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
