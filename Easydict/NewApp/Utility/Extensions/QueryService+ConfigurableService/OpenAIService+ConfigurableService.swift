//
//  OpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

enum OpenAIModels: String, CaseIterable, Identifiable {
    var id: Self {
        self
    }

    case gpt3_5_turbo = "gpt-3.5-turbo"
    case gpt3_5_turbo_1106 = "gpt-3.5-turbo-1106"
    case gpt4
    case gpt4_32k = "gpt-4-32k"
}

@available(macOS 13.0, *)
extension EZOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(headerTitleKey: "openai_translate", service: self, keys: [.openAIAPIKey]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .openAIAPIKey,
                placeholder: "service.configuration.openai.api_key.placeholder"
            )
            // translation
//            ServiceConfigurationInputCell(
//                textFieldTitleKey: "service.configuration.openai.translation.title",
//                key: .openAITranslation,
//                placeholder: "service.configuration.openai.translation.placeholder"
//            )
            // domain
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.domain.title",
                key: .openAIDomain,
                placeholder: "service.configuration.openai.domain.placeholder"
            )
            // endpoint key
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.endpoint_key.title",
                key: .openAIEndPoint,
                placeholder: "service.configuration.openai.endpoint_key.placeholder"
            )
            // model
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.model.title",
                key: .openAIModel,
                values: OpenAIModels.allCases
            )
        }
    }
}
