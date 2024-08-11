//
//  VolcanoResponse.swift
//  Easydict
//
//  Created by Jerry on 2024-08-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - VolcanoResponse

struct VolcanoResponse: Codable {
    // MARK: Internal

    let translationList: [VolcanoTranslationList]?
    let requestId: String
    let action: String
    let version: String
    let service: String
    let region: String
    let error: VolcanoErrorResponse?

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case translationList = "TranslationList"
        case requestId = "RequestId"
        case action = "Action"
        case version = "Version"
        case service = "Service"
        case region = "Region"
        case error = "Error"
    }
}

// MARK: - VolcanoTranslationList

struct VolcanoTranslationList: Codable {
    // MARK: Internal

    let translation: String
    let detectedSourceLanguage: String

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case translation = "Translation"
        case detectedSourceLanguage = "DetectedSourceLanguage"
    }
}

// MARK: - VolcanoErrorResponse

/**
 {
   "ResponseMetadata": {
     "RequestId": "293517830492649F4BF5C3D8A1E0D9G2F",
     "Action": "TranslateText",
     "Version": "2020-06-01",
     "Service": "translate",
     "Region": "cn-north-1",
     "Error": {
       "CodeN": 100010,
       "Code": "SignatureDoesNotMatch",
       "Message": "The request signature we calculated does not match the signature you provided. Check your Secret Access Key and signing method. Consult the service documentation for details."
     }
   }
 }
 */

struct VolcanoErrorResponse: Codable {
    // MARK: Internal

    let codeN: Int
    let code: String
    let message: String

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case codeN = "CodeN"
        case code = "Code"
        case message = "Message"
    }
}
