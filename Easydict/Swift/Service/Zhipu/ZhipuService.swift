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
    // zhipu free model https://docs.bigmodel.cn/cn/guide/start/model-overview
    // rate-limits: https://www.bigmodel.cn/usercenter/proj-mgmt/rate-limits

    // GLM free models https://docs.bigmodel.cn/cn/guide/start/model-overview
    case glm_4_5_flash = "glm-4.5-flash" // 128K context, 96K output, 2 QoS
    case glm_4_flash_250414 = "glm-4-flash-250414" // 128K context, 16k output, 30 QoS
    case glm_4_flash = "glm-4-flash" // glm-4-flash, 128K context, 4k output, 200 QoS
    case glm_z1_flash = "glm-z1-flash" // 128K context, 32K output, 30 QoS

    // GLM 4.5 series
    case glm_4_5 = "glm-4.5" // 128K context, 96K output, 20 QoS
    case glm_4_5_x = "glm-4.5-x" // 128K context, 96K output, 1 QoS
    case glm_4_5_air = "glm-4.5-air" // 128K context, 96K output, 30 QoS
    case glm_4_5_airx = "glm-4.5-airx" // 128K context, 96K output, 5 QoS

    // GLM Z1 series
    case glm_z1_air = "glm-z1-air" // 128K context, 32K output, 30 QoS
    case glm_z1_airx = "glm-z1-airx" // 32K context, 30K output, 30 QoS
    case glm_z1_flashx = "glm-z1-flashx" // 128K context, 8K output, 50 QoS
}
