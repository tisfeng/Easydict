//
//  VolcanoResponse.swift
//  Easydict
//
//  Created by Jerry on 2024-08-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - VolcanoResponse

struct VolcanoResponse: Decodable {
    // MARK: Internal

    let translationList: [VolcanoTranslation]?
    let responseMetadata: VolcanoResponseMetadata

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case translationList = "TranslationList"
        case responseMetadata = "ResponseMetadata"
    }
}

// MARK: - VolcanoResponseMetadata

struct VolcanoResponseMetadata: Decodable {
    // MARK: Internal

    let requestId: String
    let action: String
    let version: String
    let service: String
    let region: String
    let error: VolcanoError?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case requestId = "RequestId"
        case action = "Action"
        case version = "Version"
        case service = "Service"
        case region = "Region"
        case error = "Error"
    }
}

// MARK: - VolcanoTranslation

struct VolcanoTranslation: Decodable {
    // MARK: Internal

    struct Extra: Decodable {
        // MARK: Internal

        let sourceLanguage: String
        let inputCharacters: String

        // MARK: Private

        private enum CodingKeys: String, CodingKey {
            case sourceLanguage = "source_language"
            case inputCharacters = "input_characters"
        }
    }

    let translation: String
    let detectedSourceLanguage: String
    let extra: Extra?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case translation = "Translation"
        case detectedSourceLanguage = "DetectedSourceLanguage"
        case extra = "Extra"
    }
}

// MARK: - VolcanoError

struct VolcanoError: Decodable {
    // MARK: Internal

    let code: String
    let message: String

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case code = "Code"
        case message = "Message"
    }
}
