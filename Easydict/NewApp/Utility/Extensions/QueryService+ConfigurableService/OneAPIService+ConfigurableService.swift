//
//  OneAPIService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/26.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension OneAPIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(service: self, observeKeys: [.oneAPIAPIKey, .oneAPIEndPoint, .oneAPIModel]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .oneAPIAPIKey,
                placeholder: "service.configuration.openai.api_key.placeholder"
            )
            // endpoint
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.oneapi.endpoint.title",
                key: .oneAPIEndPoint,
                placeholder: "service.configuration.openai.endpoint.placeholder"
            )
            // model
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.model.title",
                key: .oneAPIModel,
                placeholder: "service.configuration.oneapi.model.placeholder"
            )

            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.translation.title",
                key: .oneAPITranslation
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.sentence.title",
                key: .oneAPISentence
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.dictionary.title",
                key: .oneAPIDictionary
            )
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.usage_status.title",
                key: .oneAPIServiceUsageStatus,
                values: OpenAIUsageStats.allCases
            )
        }
    }
}
