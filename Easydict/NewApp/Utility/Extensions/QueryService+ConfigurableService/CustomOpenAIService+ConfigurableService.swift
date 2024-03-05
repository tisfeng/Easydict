//
//  CustomOpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/26.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

@available(macOS 13.0, *)
extension CustomOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.customOpenAIAPIKey, .customOpenAIEndPoint, .customOpenAIModel]
        ) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .customOpenAIAPIKey,
                placeholder: "service.configuration.openai.api_key.placeholder"
            )
            // endpoint
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.endpoint.title",
                key: .customOpenAIEndPoint,
                placeholder: "service.configuration.openai.endpoint.placeholder"
            )
            // model
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.model.title",
                key: .customOpenAIModel,
                placeholder: "service.configuration.custom_openai.model.placeholder"
            )

            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.translation.title",
                key: .customOpenAITranslation
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.sentence.title",
                key: .customOpenAISentence
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.dictionary.title",
                key: .customOpenAIDictionary
            )
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.usage_status.title",
                key: .customOpenAIServiceUsageStatus,
                values: OpenAIUsageStats.allCases
            )
        }
    }
}
