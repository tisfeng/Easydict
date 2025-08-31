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
    // MARK: Lifecycle

    // Custom initializer for default values
    init(
        text: String,
        sourceLanguage: String? = nil,
        targetLanguage: String,
        serviceType: String,
        appleDictionaryNames: [String]? = nil,
        queryType: EZQueryTextType = []
    ) {
        self.text = text
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.serviceType = serviceType
        self.appleDictionaryNames = appleDictionaryNames
        self.queryType = queryType
    }

    /// Custom initializer to handle optional queryType in JSON
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decode(String.self, forKey: .text)
        self.sourceLanguage = try container.decodeIfPresent(String.self, forKey: .sourceLanguage)
        self.targetLanguage = try container.decode(String.self, forKey: .targetLanguage)
        self.serviceType = try container.decode(String.self, forKey: .serviceType)
        self.appleDictionaryNames = try container.decodeIfPresent(
            [String].self, forKey: .appleDictionaryNames
        )
        self.queryType = try container.decodeIfPresent(EZQueryTextType.self, forKey: .queryType) ?? []
    }

    // MARK: Internal

    var text: String
    var sourceLanguage: String? // BCP-47 language code. If sourceLanguage is nil, it will be auto detected.
    var targetLanguage: String
    var serviceType: String
    var appleDictionaryNames: [String]?
    var queryType: EZQueryTextType // [] means auto detect query type.

    // MARK: - Custom encode method to handle optional fields properly

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(sourceLanguage, forKey: .sourceLanguage)
        try container.encode(targetLanguage, forKey: .targetLanguage)
        try container.encode(serviceType, forKey: .serviceType)
        try container.encodeIfPresent(appleDictionaryNames, forKey: .appleDictionaryNames)
        try container.encode(queryType, forKey: .queryType)
    }

    // MARK: Private

    // Custom Codable implementation to handle optional queryType in JSON
    private enum CodingKeys: String, CodingKey {
        case text, sourceLanguage, targetLanguage, serviceType, appleDictionaryNames, queryType
    }
}

// MARK: - TranslationResponse

struct TranslationResponse: Content {
    var translatedText: String
    var sourceLanguage: String
    var HTMLStrings: [String]?
    var dictionaryEntry: DictionaryEntry?
}

// MARK: - OCRRequest

struct OCRRequest: Content {
    var imageData: Data
    var sourceLanguage: String?
}

// MARK: - OCRResponse

struct OCRResponse: Content {
    var ocrText: String
    var sourceLanguage: String
}

// MARK: - DetectRequest

struct DetectRequest: Content {
    var text: String
}

// MARK: - DetectResponse

struct DetectResponse: Content {
    var sourceLanguage: String // BCP-47 language code
}

// MARK: - GetSelectedTextResponse

struct GetSelectedTextResponse: Content {
    var selectedText: String?
}

// MARK: - EZQueryTextType + Codable

extension EZQueryTextType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(UInt.self)
        self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
