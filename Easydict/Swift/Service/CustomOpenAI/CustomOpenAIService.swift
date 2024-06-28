//
//  CustomOpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/16.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

@objc(EZCustomOpenAIService)
class CustomOpenAIService: BaseOpenAIService {
    // MARK: Public

    public override func name() -> String {
        let serviceName = Defaults[super.nameKey]
        return serviceName.isEmpty ? NSLocalizedString("custom_openai", comment: "") : serviceName
    }

    override public func serviceType() -> ServiceType {
        .customOpenAI
    }

    // MARK: Internal

    override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
//            viewModel: viewModel,
            showNameSection: true
        )
    }
}
