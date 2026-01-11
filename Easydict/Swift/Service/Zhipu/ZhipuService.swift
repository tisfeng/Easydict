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
    // pricing: https://open.bigmodel.cn/pricing
    // rate-limits: https://www.bigmodel.cn/usercenter/proj-mgmt/rate-limits

    // GLM free models https://docs.bigmodel.cn/cn/guide/start/model-overview
    case glm_4_5_flash = "glm-4.5-flash" // 128K context, 96K output, 2 QoS
    case glm_4_flash_250414 = "glm-4-flash-250414" // 128K context, 16k output, 30 QoS

    // GLM Pro models
    case glm_4_7 = "glm-4.7" // 200K context, 128K output, 20 QoS
    case glm_4_5_air = "glm-4.5-air" // 128K context, 96K output, 30 QoS
}
