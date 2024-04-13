//
//  BuiltInAIService.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

@objc(EZBuiltInAIService)
class BuiltInAIService: BaseOpenAIService {
    // MARK: Lifecycle

    override init() {
        super.init()
    }

    // MARK: Public

    override public func name() -> String {
        NSLocalizedString("built_in_ai", comment: "")
    }

    // MARK: Internal

    override var apiKey: String {
        defaultAPIKey
    }

    override var endpoint: String {
        defaultEndpoint
    }

    override var model: String {
        get {
            defaultModel
        }

        set {}
    }

    override var availableModels: [String] {
        [defaultModel]
    }

    override func serviceType() -> ServiceType {
        .builtInAI
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        Configuration.shared.intelligentQueryTextTypeForServiceType(serviceType())
    }

    override func queryTextType() -> EZQueryTextType {
        [.translation, .dictionary, .sentence]
    }

    override func serviceUsageStatus() -> EZServiceUsageStatus {
        .alwaysOff
    }
}
