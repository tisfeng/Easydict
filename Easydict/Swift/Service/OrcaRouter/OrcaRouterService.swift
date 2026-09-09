//
//  OrcaRouterService.swift
//  Easydict
//
//  Created by jinhao.song on 2026/8/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - OrcaRouterService

@objc(EZOrcaRouterService)
class OrcaRouterService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("orcarouter_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .orcaRouter
    }

    public override func link() -> String? {
        "https://www.orcarouter.ai"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        OrcaRouterModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        OrcaRouterModel.auto.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://api.orcarouter.ai/v1/chat/completions"
    }
}

// MARK: - OrcaRouterModel

enum OrcaRouterModel: String, CaseIterable {
    // Models: https://www.orcarouter.ai
    // API: https://api.orcarouter.ai/v1

    /// Auto-routes to the best available model on the gateway.
    case auto = "orcarouter/auto"
    case fusion = "orcarouter/fusion"
    case fusionFlash = "orcarouter/fusion-flash"
    case fusionMini = "orcarouter/fusion-mini"
}
