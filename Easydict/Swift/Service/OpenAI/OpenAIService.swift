//
//  OpenAIService.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/31.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - OpenAIService

@objc(EZOpenAIService)
class OpenAIService: BaseOpenAIService {
    public override func serviceUsageStatus() -> EZServiceUsageStatus {
        // swiftlint:disable:next todo
        // TODO: Later, we need to support all services to use usage status.
        let usageStatus = Defaults[.openAIServiceUsageStatus]
        guard let value = UInt(usageStatus.rawValue) else { return .default }
        return EZServiceUsageStatus(rawValue: value) ?? .default
    }
}
