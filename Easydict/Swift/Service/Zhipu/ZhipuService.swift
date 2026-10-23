//
//  ZhipuService.swift
//  Easydict
//
//  Created by Daniel on 2025/9/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - ZhipuService

@objc(EZZhipuService)
class ZhipuService: OpenAIService {
    // MARK: Public

    public override func name() -> String {
        NSLocalizedString("zhipu_translate", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .zhipu
    }

    public override func link() -> String? {
        "https://bigmodel.cn/"
    }

    // MARK: Internal

    override var defaultModels: [String] {
        ZhipuModel.allCases.map(\.rawValue)
    }

    override var defaultModel: String {
        ZhipuModel.glm_4_flash_250414.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    }
}

// MARK: - ZhipuModel

enum ZhipuModel: String, CaseIterable {
    // zhipu model https://docs.bigmodel.cn/cn/guide/start/model-overview
    // pricing: https://bigmodel.cn/pricing
    // rate-limits: https://www.bigmodel.cn/usercenter/proj-mgmt/rate-limits

    /// The first case is the list order users see and the fallback for a saved-but-removed
    /// model ID (`StreamService.model`), so it must stay the free default; otherwise an
    /// existing user silently lands on the paid GLM-5.3-Flash.
    case glm_4_flash_250414 = "glm-4-flash-250414"

    // Keep the free IDs used by BuiltInAIService; GLM-4.5-Flash routes to GLM-4.7-Flash.
    case glm_4_5_flash = "glm-4.5-flash"

    case glm_5_3_flash = "glm-5.3-flash"
    case glm_5_3 = "glm-5.3"
}
