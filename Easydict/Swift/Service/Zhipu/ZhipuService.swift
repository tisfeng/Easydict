//
//  ZhipuService.swift
//  Easydict
//
//  Created by Daniel with Claude Code on 2025/4/19.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUICore

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
        ZhipuModel.glm4_5_air.rawValue
    }

    override var observeKeys: [Defaults.Key<String>] {
        [apiKeyKey, supportedModelsKey]
    }

    override var defaultEndpoint: String {
        "https://open.bigmodel.cn/api/paas/v4/chat/completions"
    }

    override var apiKeyPlaceholder: LocalizedStringKey {
        "your_api_key"
    }
}

 // MARK: - ZhipuModel

// swiftlint:disable identifier_name
enum ZhipuModel: String, CaseIterable {
    // Docs: https://docs.bigmodel.cn/cn/guide/start/model-overview.md

    // Latest Models
    case glm4_5 = "glm-4.5"
    case glm4_5_air = "glm-4.5-air"
    case glm4_5_x = "glm-4.5-x"
    case glm4_5_airx = "glm-4.5-airx"
    case glm4_5_flash = "glm-4.5-flash"
    case glm4_plus = "glm-4-plus"
    case glm4_air = "glm-4-air-250414"
    case glm4_airx = "glm-4-airx"
    case glm4_flashx = "glm-4-flashx"
    case glm4_flashx_250414 = "glm-4-flashx-250414"
    
    // Z1 Series
    case glm_z1_air = "glm-z1-air"
    case glm_z1_airx = "glm-z1-airx"
    case glm_z1_flash = "glm-z1-flash"
    case glm_z1_flashx = "glm-z1-flashx"
}

// swiftlint:enable identifier_name
