//
//  TokenHubService.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - TokenHubService

class TokenHubService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("tokenhub_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .tokenHub
    }

    public override func link() -> String? {
        "https://cloud.tencent.com/document/product/1823/130078"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        TokenHubModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        TokenHubModel.hyMT2Lite.rawValue
    }

    override var defaultEndpoint: String {
        "https://tokenhub.tencentmaas.com/v1/chat/completions"
    }
}

// MARK: - TokenHubModel

/// TokenHub translation models that support OpenAI Chat Completions.
enum TokenHubModel: String, CaseIterable {
    case hyMT2Pro = "hy-mt2-pro"
    case hyMT2Plus = "hy-mt2-plus"
    case hyMT2Lite = "hy-mt2-lite"
}
