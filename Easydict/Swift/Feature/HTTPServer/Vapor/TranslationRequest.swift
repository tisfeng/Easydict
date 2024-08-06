//
//  TranslationRequest.swift
//  Easydict
//
//  Created by tisfeng on 2024/8/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Vapor

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
    case invalidParameter(String)

    // MARK: Internal

    var status: HTTPResponseStatus {
        switch self {
        case .invalidParameter, .unsupportedServiceType:
            .badRequest
        }
    }

    var reason: String {
        switch self {
        case let .unsupportedServiceType(serviceType):
            "Unsupported service type: \(serviceType)"
        case let .invalidParameter(parameter):
            "Invalid parameter: \(parameter)"
        }
    }
}
