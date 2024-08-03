//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Vapor

func routes(_ app: Application) throws {
    app.get { _ async in
        "Hello, Welcome to Easydict server!"
    }

    app.post("translate") { req async throws -> TranslationResponse in
        let request = try req.content.decode(TranslationRequest.self)
        let serviceType = ServiceType(rawValue: request.serviceType)
        let appleDictionaryNames = request.appleDictionaryNames

        guard let service = ServiceTypes.shared().service(withType: serviceType) else {
            throw TranslationError.unsupportedServiceType(serviceType.rawValue)
        }

        if let appleDictionary = service as? AppleDictionary, let appleDictionaryNames {
            appleDictionary.appleDictionaryNames = appleDictionaryNames
        }

        if service.isStream() {
            throw TranslationError
                .invalidParameter(
                    "\(serviceType.rawValue) is stream service, which does not support 'translate' API. Please use 'streamTranslate."
                )
        }

        let result = try await service.translate(request: request)

        var response = TranslationResponse(
            translatedText: result.translatedText ?? "",
            sourceLanguage: result.from.code
        )

        if service is AppleDictionary {
            response.HTMLStrings = result.htmlStrings
        }

        return response
    }

    #if DEBUG
    // Currently, streamTranslate only supports base OpenAI services for test.
    app.post("streamTranslate") { req async throws -> Response in
        let request = try req.content.decode(TranslationRequest.self)
        let serviceType = ServiceType(rawValue: request.serviceType)

        guard let service = ServiceTypes.shared().service(withType: serviceType) else {
            throw TranslationError.unsupportedServiceType(serviceType.rawValue)
        }

        guard let streamService = service as? LLMStreamService else {
            throw TranslationError
                .invalidParameter(
                    "\(serviceType.rawValue) isn't stream service, which does not support 'streamTranslate' API. Please use 'translate."
                )
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
                    let chatStreamResults = try await streamService.streamTranslate(request: request)
                    for try await streamResult in chatStreamResults {
                        if let json = streamResult.jsonString {
                            let event = "data: \(json)\n\n"
                            try await writer.write(.buffer(.init(string: event)))
                        }
                    }
                } catch {
                    try? await writer.write(.error(error))
                }
                try? await writer.write(.end)
            })
        )
    }
    #endif
}
