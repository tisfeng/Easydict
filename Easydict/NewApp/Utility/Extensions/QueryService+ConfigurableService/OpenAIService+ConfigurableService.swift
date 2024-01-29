//
//  OpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

protocol ServiceSecretConfigrable {
    func resetSecret()

    func validate()
}

extension ServiceSecretConfigrable {
    func resetSecret() {}

    func validate() {}
}

extension QueryService: ServiceSecretConfigrable {}

extension EZOpenAIService {
    func resetSecret() {}

    func validate() {}
}

@available(macOS 13.0, *)
extension EZOpenAIService: ConfigurableService {
//    func resetSecret() {
//        Defaults[.openAIAPIKey] = ""
//        Defaults[.openAITranslation] = ""
//    }
//
//    func validate() {}

    func configurationListItems() -> some View {
//        ServiceStringConfigurationSection(
//            textFieldTitleKey: "service.configuration.openai.api_key.header",
//            headerTitleKey: "service.configuration.openai.api_key.title",
//            key: .openAIAPIKey,
//            prompt: "service.configuration.openai.api_key.prompt",
//            footer: {
//                Text("service.configuration.openai.api_key.footer")
//            }
//        )
//
//        ServiceStringConfigurationSection(
//            textFieldTitleKey: "service.configuration.openai.translation.header",
//            headerTitleKey: "service.configuration.openai.translation.title",
//            key: .openAITranslation,
//            prompt: "service.configuration.openai.translation.prompt",
//            footer: {
//                Text("service.configuration.openai.translation.footer")
//            }
//        )

        ServiceConfigurationSectionView(headerTitleKey: "service.configuration.openai.header", service: self) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .openAIAPIKey,
                placeholder: "service.configuration.openai.api_key.prompt"
            )
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.translation.title",
                key: .openAITranslation,
                placeholder: "service.configuration.openai.translation.prompt"
            )
        }
    }
}
