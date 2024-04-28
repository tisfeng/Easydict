//
//  DefaultsStoredKey.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

func storedKey(_ key: String, serviceType: ServiceType) -> String {
    // This key should be compatible with existing OpenAI config keys
    // EZOpenAIServiceUsageStatusKey
    // EZOpenAIDictionaryKey
    "EZ" + serviceType.rawValue + key + "Key"
}

func serviceUsageStatusStoredKey(_ serviceType: ServiceType) -> String {
    storedKey(EZServiceUsageStatusKey, serviceType: serviceType)
}

func translationStoredKey(_ serviceType: ServiceType) -> String {
    storedKey(EZTranslationKey, serviceType: serviceType)
}

func sentenceStoredKey(_ serviceType: ServiceType) -> String {
    storedKey(EZSentenceKey, serviceType: serviceType)
}

func dictionaryStoredKey(_ serviceType: ServiceType) -> String {
    storedKey(EZDictionaryKey, serviceType: serviceType)
}

extension UserDefaults {
    static func bool(forKey key: String, serviceType: ServiceType) -> Bool {
        let key = storedKey(key, serviceType: serviceType)
        let value = standard.bool(forKey: key)
        return value
    }

    static func string(forKey key: String, serviceType: ServiceType) -> String? {
        let key = storedKey(key, serviceType: serviceType)
        let value = standard.string(forKey: key)
        return value
    }
}
