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

    app.post("streamTranslate") { req async throws -> Response in
        let request = try req.content.decode(TranslationRequest.self)
        let serviceType = ServiceType(rawValue: request.serviceType)

        guard let service = ServiceTypes.shared().service(withType: serviceType) else {
            throw TranslationError.unsupportedServiceType(serviceType.rawValue)
        }

        guard let streamService = service as? LLMStreamService else {
            throw TranslationError.unsupportedServiceType(serviceType.rawValue)
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
                    let translatedTexts = try await streamService.streamTranslateText(request: request)
                    for try await content in translatedTexts {
                        let event = "data: \(content)\n\n"
                        try await writer.write(.buffer(.init(string: event)))
                    }
                } catch {
                    try? await writer.write(.error(error))
                }
                try? await writer.write(.end)
            })
        )
    }
}

// MARK: - TranslationRequest

struct TranslationRequest: Content {
    var text: String
    var sourceLanguage: String? // BCP-47 language code. If sourceLanguage is nil, it will be auto detected.
    var targetLanguage: String
    var serviceType: String
    var appleDictionaryNames: [String]?
}

// MARK: - TranslationResponse

struct TranslationResponse: Content {
    var translatedText: String
    var sourceLanguage: String
    var HTMLStrings: [String]?
}

// MARK: - TranslationError

enum TranslationError: Error, AbortError {
    case unsupportedServiceType(String)

    // MARK: Internal

    var status: HTTPResponseStatus {
        switch self {
        case .unsupportedServiceType:
            .badRequest
        }
    }

    var reason: String {
        switch self {
        case let .unsupportedServiceType(serviceType):
            "Unsupported service type: \(serviceType)"
        }
    }
}
