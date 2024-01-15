//
//  OpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

@available(macOS 12.0, *)
extension EZOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceStringConfigurationSection(
            textFieldTitleKey: "service.configuration.openai.api_key.header",
            headerTitleKey: "service.configuration.openai.api_key.title",
            key: .openAIAPIKey,
            prompt: "service.configuration.openai.api_key.prompt",
            footer: {
                Text("service.configuration.openai.api_key.footer")
            }
        )

        ServiceStringConfigurationSection(
            textFieldTitleKey: "service.configuration.openai.translation.header",
            headerTitleKey: "service.configuration.openai.translation.title",
            key: .openAITranslation,
            prompt: "service.configuration.openai.translation.prompt",
            footer: {
                Text("service.configuration.openai.translation.footer")
            }
        )
    }
}
