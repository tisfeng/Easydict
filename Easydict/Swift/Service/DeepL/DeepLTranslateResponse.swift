//
//  DeepLTranslateResponse.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - DeepLTranslateResponse

/// DeepL Web Translate Response
///
/// Example response:
/// ```json
/// {
///   "id": 138686000,
///   "jsonrpc": "2.0",
///   "result": {
///     "detectedLanguages": {
///       "EN": 0.048519,
///       "ZH": 0.010874,
///       ...
///     },
///     "lang": "EN",
///     "lang_is_confident": false,
///     "texts": [
///       {
///         "alternatives": [
///           { "text": "不错" },
///           { "text": "好" },
///           { "text": "好的" }
///         ],
///         "text": "很好"
///       }
///     ]
///   }
/// }
/// ```
struct DeepLTranslateResponse: Codable {
    let id: Int?
    let jsonrpc: String?
    let result: DeepLTranslateResult?
}

// MARK: - DeepLTranslateResult

struct DeepLTranslateResult: Codable {
    enum CodingKeys: String, CodingKey {
        case detectedLanguages
        case lang
        case langIsConfident = "lang_is_confident"
        case texts
    }

    let detectedLanguages: [String: Double]?
    let lang: String?
    let langIsConfident: Bool?
    let texts: [DeepLTranslateText]?
}

// MARK: - DeepLTranslateText

struct DeepLTranslateText: Codable {
    let alternatives: [DeepLTranslateAlternative]?
    let text: String?
}

// MARK: - DeepLTranslateAlternative

struct DeepLTranslateAlternative: Codable {
    let text: String?
}

// MARK: - DeepLOfficialResponse

/// DeepL Official API Response
///
/// Example response:
/// ```json
/// {
///   "translations": [
///     {
///       "detected_source_language": "EN",
///       "text": "很好"
///     }
///   ]
/// }
/// ```
struct DeepLOfficialResponse: Codable {
    let translations: [DeepLOfficialTranslation]?
}

// MARK: - DeepLOfficialTranslation

struct DeepLOfficialTranslation: Codable {
    enum CodingKeys: String, CodingKey {
        case detectedSourceLanguage = "detected_source_language"
        case text
    }

    let detectedSourceLanguage: String?
    let text: String?
}
