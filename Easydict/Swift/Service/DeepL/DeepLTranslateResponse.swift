//
//  DeepLTranslateResponse.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - DeepLWebTranslateRequest

/// Request body used by DeepL's anonymous oneshot translation endpoint.
struct DeepLWebTranslateRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case text
        case targetLang = "target_lang"
        case sourceLang = "source_lang"
        case usageType = "usage_type"
        case appInformation = "app_information"
    }

    let text: [String]
    let targetLang: String
    let sourceLang: String?
    let usageType: String
    let appInformation: DeepLAppInformation
}

// MARK: - DeepLAppInformation

/// Client profile fields expected by the DeepL interactive-client endpoint.
struct DeepLAppInformation: Encodable {
    enum CodingKeys: String, CodingKey {
        case os
        case osVersion = "os_version"
        case appVersion = "app_version"
        case appBuild = "app_build"
        case instanceID = "instance_id"
    }

    let os: String
    let osVersion: String
    let appVersion: String
    let appBuild: String
    let instanceID: String
}

// MARK: - DeepLOfficialResponse

/// Shared response returned by DeepL's official and oneshot translation endpoints.
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
