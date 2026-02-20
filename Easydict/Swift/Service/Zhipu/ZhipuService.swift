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
    // pricing snapshot date: 2026-02-20
    // note: prices are a snapshot and may change over time.
    // note: "TBD" means the model is not explicitly listed on the pricing snapshot page.
    // rate-limits: https://www.bigmodel.cn/usercenter/proj-mgmt/rate-limits

    // Text models
    case glm_5 = "glm-5" // Input CNY 4-6 / 1M tokens; output CNY 18-22 / 1M tokens (tiered).
    case glm_4_7 = "glm-4.7" // Input CNY 2-4 / 1M tokens; output CNY 8-16 / 1M tokens (tiered).
    case glm_4_7_flash = "glm-4.7-flash" // Free.
    case glm_4_7_flashx = "glm-4.7-flashx" // Input CNY 0.5 / 1M tokens; output CNY 3 / 1M tokens.
    case glm_4_6 = "glm-4.6" // TBD.
    case glm_4_5_air = "glm-4.5-air" // Input CNY 0.8-1.2 / 1M tokens; output CNY 2-8 / 1M tokens (tiered).
    case glm_4_5_airx = "glm-4.5-airx" // TBD.
    case glm_4_5_flash = "glm-4.5-flash" // TBD.
    case glm_4_flash_250414 = "glm-4-flash-250414" // Free.
    case glm_4_flashx_250414 = "glm-4-flashx-250414" // CNY 0.1 / 1M tokens (single-rate listing).

    // Multimodal models
    case glm_4_6v = "glm-4.6v" // Input CNY 1-2 / 1M tokens; output CNY 3-6 / 1M tokens (tiered).
    case glm_4_6v_flash = "glm-4.6v-flash" // Free.
    case glm_4_6v_flashx = "glm-4.6v-flashx" // Input CNY 0.15-0.3 / 1M tokens; output CNY 1.5-3 / 1M tokens (tiered).
    case glm_4v_flash = "glm-4v-flash" // Free.
    case glm_4_1v_thinking_flashx = "glm-4.1v-thinking-flashx" // CNY 2 / 1M tokens (single-rate listing).
    case glm_4_1v_thinking_flash = "glm-4.1v-thinking-flash" // Free.
}
