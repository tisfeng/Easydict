//
//  QueryService+Stream.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/27.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import Vapor

// MARK: - TranslationStream

class TranslationStream: AsyncSequence {
    // MARK: Lifecycle

    init(request: TranslationRequest) {
        self.request = request
    }

    // MARK: Internal

    typealias Element = TranslationResponse

    func makeAsyncIterator() -> TranslationStreamIterator {
        TranslationStreamIterator(request: request)
    }

    // MARK: Private

    private let request: TranslationRequest
}

// MARK: - TranslationStreamIterator

struct TranslationStreamIterator: AsyncIteratorProtocol {
    // MARK: Lifecycle

    init(request: TranslationRequest) {
        self.request = request
    }

    // MARK: Internal

    typealias Element = TranslationResponse

    mutating func next() async throws -> TranslationResponse? {
        let serviceType = ServiceType(rawValue: request.serviceType)

        guard let service = ServiceTypes.shared().service(withType: serviceType) else {
            throw TranslationError.unsupportedServiceType(serviceType.rawValue)
        }

        guard service is LLMStreamService else {
            throw TranslationError.unsupportedServiceType(serviceType.rawValue)
        }

        let result = try await service.translate(request: request)

        return TranslationResponse(translatedText: result.translatedText ?? "", sourceLanguage: result.from.code)
    }

    // MARK: Private

    private let request: TranslationRequest
}
