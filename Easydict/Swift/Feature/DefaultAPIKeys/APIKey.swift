//
//  APIKey.swift
//  Easydict
//
//  Created by tisfeng on 2024/2/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - APIKey

extension BuiltInAIService {
    var builtInAIAPIKey: String {
        APIKey.builtInAIAPIKey.stringValue
    }

    var builtInAIEndpoint: String {
        APIKey.builtInAIEndpoint.stringValue
    }
}

extension CaiyunService {
    var caiyunToken: String {
        APIKey.caiyunToken.stringValue
    }
}

extension TencentService {
    var tencentSecretId: String {
        APIKey.tencentSecretId.stringValue
    }

    var tencentSecretKey: String {
        APIKey.tencentSecretKey.stringValue
    }
}

extension EZNiuTransTranslate {
    @objc var niutransAPIKey: String {
        APIKey.niutransAPIKey.stringValue
    }
}

extension VolcanoService {
    var volcanoAccessKeyID: String {
        APIKey.volcanoAccessKeyID.stringValue
    }

    var volcanoSecretAccessKey: String {
        APIKey.volcanoSecretAccessKey.stringValue
    }
}

// MARK: - APIKey

enum APIKey: String {
    /**
     For convenience, we provide a default key for users to try out the service.
     Please do not abuse it, otherwise it may be revoked.
     */

    case openAIAPIKey
    case openAIEndpoint
    case geminiAPIKey
    case caiyunToken
    case tencentSecretId
    case tencentSecretKey
    case niutransAPIKey
    case builtInAIAPIKey
    case builtInAIEndpoint
    case builtInAIModel
    case volcanoAccessKeyID
    case volcanoSecretAccessKey

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
