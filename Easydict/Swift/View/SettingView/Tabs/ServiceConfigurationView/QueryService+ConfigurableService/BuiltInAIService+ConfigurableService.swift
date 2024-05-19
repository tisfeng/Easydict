//
//  BuiltInAIService+ConfigurableService.swift
//  Easydict
//
//  Created by tisfeng on 2024/4/28.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SwiftUI

// MARK: - BuiltInAIService + ConfigurableService

extension BuiltInAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(
            service: self, observeKeys: []
        ) {
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.translation.title",
                key: .builtInAITranslation
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.sentence.title",
                key: .builtInAISentence
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.dictionary.title",
                key: .builtInAIDictionary
            )
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.usage_status.title",
                key: .builtInAIServiceUsageStatus,
                values: OpenAIUsageStats.allCases
            )
        }
    }
}
