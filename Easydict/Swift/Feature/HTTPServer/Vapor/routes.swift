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

        guard let service = GlobalContext.shared.getService(ofType: serviceType) else {
            throw TranslationError.unsupportedServiceType(serviceType.rawValue)
        }

        let result = try await service.translate(request: request)

        var response = TranslationResponse(
            translatedText: result.translatedText ?? "",
            sourceLanguage: result.from.code
        )

        if let appleDictioanry = service as? AppleDictionary {
            response.html = result.htmlString
        }

        return response
    }
}

// MARK: - TranslationRequest

struct TranslationRequest: Content {
    var text: String
    var sourceLanguage: String? // BCP-47 language code. If sourceLanguage is nil, it will be auto detected.
    var targetLanguage: String
    var serviceType: String
}

// MARK: - TranslationResponse

struct TranslationResponse: Content {
    var translatedText: String
    var sourceLanguage: String
    var html: String?
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
