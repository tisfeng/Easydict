//
//  CustomOpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/16.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZCustomOpenAIService)
class CustomOpenAIService: BaseOpenAIService {
    // MARK: Public

    override public func name() -> String {
        let name = Defaults[.customOpenAINameKey]
        if let name, !name.isEmpty {
            return name
        }
        return NSLocalizedString("custom_openai", comment: "The name of Custom OpenAI Translate")
    }

    override public func serviceType() -> ServiceType {
        .customOpenAI
    }

    // MARK: Internal

    override var apiKey: String {
        Defaults[.customOpenAIAPIKey] ?? ""
    }

    override var endpoint: String {
        Defaults[.customOpenAIEndPoint] ?? ""
    }

    override var model: String {
        get {
            Defaults[.customOpenAIModel]
        }

        set {
            Defaults[.customOpenAIModel] = newValue
        }
    }

    override var availableModels: [String] {
        Defaults[.customOpenAIVaildModels]
    }
}
