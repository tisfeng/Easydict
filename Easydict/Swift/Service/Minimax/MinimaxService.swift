//
//  MinimaxService.swift
//  Easydict
//
//  Created by Codex on 2026/2/20.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - MinimaxService

@objc(EZMinimaxService)
class MinimaxService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("minimax_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .miniMax
    }

    public override func link() -> String? {
        "https://platform.minimaxi.com/"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        MiniMaxModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        MiniMaxModel.minimax_m2_5.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://api.minimaxi.com/v1/chat/completions"
    }
}

// MARK: - MiniMaxModel

enum MiniMaxModel: String, CaseIterable {
    // Docs: https://platform.minimaxi.com/docs/api-reference/text-openai-api#支持的模型

    case minimax_m2_5 = "MiniMax-M2.5"
    case minimax_m2_5_highspeed = "MiniMax-M2.5-highspeed"
    case minimax_m2_1 = "MiniMax-M2.1"
    case minimax_m2_1_highspeed = "MiniMax-M2.1-highspeed"
    case minimax_m2 = "MiniMax-M2"
}
