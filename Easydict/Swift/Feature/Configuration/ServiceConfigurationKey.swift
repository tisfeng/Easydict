//
//  ServiceConfigurationKey.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

func serivceConfigurationKey<T: _DefaultsSerializable>(
    _ key: ServiceConfigurationKey,
    serviceType: ServiceType,
    id: String? = nil,
    defaultValue: T
)
    -> Defaults.Key<T> {
    // This key should be compatible with existing OpenAI config keys
    // EZOpenAIServiceUsageStatusKey
    // EZOpenAIDictionaryKey
    // EZOpenAIDictionary_ID_Key

    var identifier = ""
    if let id, !id.isEmpty {
        identifier = "_\(id)_"
    }
    let key = "EZ" + serviceType.rawValue + key.rawValue.capitalizeFirstLetter() + identifier + "Key"
    return .init(key, default: defaultValue)
}

extension String {
    func capitalizeFirstLetter() -> String {
        prefix(1).uppercased() + dropFirst()
    }
}

// MARK: - ServiceConfigurationKey

enum ServiceConfigurationKey: String {
    case serviceUsageStatus
    case translation
    case dictionary
    case sentence
    case supportedModels = "AvailableModels" // save in String: "gpt-3.5, gpt-4"
    case validModels // save in [String]
    case model
    case apiKey = "API"
    case endpoint = "EndPoint"
    case name
    case enableCustomPrompt
    case systemPrompt
    case userPrompt
    case thinkTag
    case temperature
}
