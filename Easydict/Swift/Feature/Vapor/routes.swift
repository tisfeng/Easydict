//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Vapor

// MARK: - TranslationRequest

struct TranslationRequest: Content {
    var text: String
    var sourceLanguage: String?
    var targetLanguage: String
    var serviceType: String
}

// MARK: - TranslationResponse

struct TranslationResponse: Content {
    var sourceLanguage: String
    var targetLanguage: String
    var translation: String
}

func routes(_ app: Application) throws {
    app.get { _ async in
        "Easydict"
    }

    app.get("hello") { _ async -> String in
        "Hello, Welcome to Easydict!"
    }

    app.post("translate") { req -> EventLoopFuture<Response> in
        let request = try req.content.decode(TranslationRequest.self)
        let serviceType = ServiceType(rawValue: request.serviceType)

        let response = Response(status: .ok, headers: ["Content-Type": "application/json"])

        guard let service = GlobalContext.shared.getService(ofType: serviceType) else {
            return req.eventLoop.makeFailedFuture(TranslationError.notFoundServiceType)
        }

        service.result = EZQueryResult()

        let promise = req.eventLoop.makePromise(of: Response.self)

        service.translate(request: request) { result, error in
            if let error {
                promise.fail(error)
                return
            }

            let translationResponse = TranslationResponse(
                sourceLanguage: result.from.rawValue,
                targetLanguage: result.to.rawValue,
                translation: result.translatedText ?? ""
            )

            do {
                let responseBody = try JSONEncoder().encode(translationResponse)
                response.body = .init(data: responseBody)
                promise.succeed(response)
            } catch {
                promise.fail(error)
            }
        }

        return promise.futureResult
    }
}

extension QueryService {
    func translate(request: TranslationRequest, completion: @escaping (EZQueryResult, Error?) -> ()) {
        let text = request.text
        let from = Language.language(fromCode: request.sourceLanguage ?? "auto")
        let to = Language.language(fromCode: request.targetLanguage)

        if prehandleQueryTextLanguage(
            text,
            from: from,
            to: to,
            completion: completion
        ) {
            return
        }

        translate(text, from: from, to: to, completion: completion)
    }
}

// MARK: - TranslationError

enum TranslationError: Error, AbortError {
    case notFoundServiceType
    case translationFailed(String)

    // MARK: Internal

    var status: HTTPResponseStatus {
        switch self {
        case .notFoundServiceType:
            .badRequest
        case .translationFailed:
            .internalServerError
        }
    }

    var reason: String {
        switch self {
        case .notFoundServiceType:
            "Service type not found"
        case let .translationFailed(message):
            message
        }
    }
}
