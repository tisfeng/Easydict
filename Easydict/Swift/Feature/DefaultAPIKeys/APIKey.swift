//
//  APIKey.swift
//  Easydict
//
//  Created by tisfeng on 2024/2/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

extension OpenAIService {
    var defaultAPIKey: String {
        APIKey.openAIAPIKey.stringValue
    }

    var defaultEndPoint: String {
        APIKey.openAIEndPoint.stringValue
    }
}

extension GeminiService {
    var defaultAPIKey: String {
        APIKey.geminiAPIKey.stringValue
    }
}

extension CaiyunService {
    var defaultToken: String {
        APIKey.caiyunToken.stringValue
    }
}

extension TencentService {
    var defaultSecretId: String {
        APIKey.tencentSecretId.stringValue
    }

    var defaultSecretKey: String {
        APIKey.tencentSecretKey.stringValue
    }
}

extension EZNiuTransTranslate {
    @objc var defaultAPIKey: String {
        APIKey.niutransAPIKey.stringValue
    }
}

// MARK: - APIKey

enum APIKey: String {
    /**
     For convenience, we provide a default key for users to try out the service.
     Please do not abuse it, otherwise it may be revoked.
     */

    case openAIAPIKey
    case openAIEndPoint
    case geminiAPIKey
    case caiyunToken
    case tencentSecretId
    case tencentSecretKey
    case niutransAPIKey

    // MARK: Internal

    var stringValue: String {
        SecretKeyManager.keyValues[rawValue] ?? ""
    }
}

// MARK: - SecretKeyManager

@objcMembers
class SecretKeyManager: NSObject {
    static var keyValues: [String: String] {
        guard let path = Bundle.main.path(forResource: "EncryptedSecretKeys", ofType: "plist") else {
            return [:]
        }

        guard let dict = NSDictionary(contentsOfFile: path) else {
            return [:]
        }

        var decryptedKeyValues = [String: String]()
        for (key, value) in dict {
            if let key = key as? String, let value = value as? String {
                decryptedKeyValues[key] = value.decryptAES()
            }
        }

        return decryptedKeyValues
    }
}
