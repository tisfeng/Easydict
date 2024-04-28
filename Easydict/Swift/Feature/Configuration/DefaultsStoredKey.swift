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
