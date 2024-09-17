//
//  StreamConfigurationView.swift
//  Easydict
//
//  Created by tisfeng on 2024/6/20.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation
import SwiftUI

// MARK: - StreamConfigurationView

struct StreamConfigurationView: View {
    // MARK: Lifecycle

    init(
        service: LLMStreamService,
        showNameSection: Bool = false,
        showAPIKeySection: Bool = true,
        showEndpointSection: Bool = true,
        showSupportedModelsSection: Bool = true,
        showUsedModelSection: Bool = true,
        showCustomPromptSection: Bool = false,
        showTranslationToggle: Bool = true,
        showSentenceToggle: Bool = true,
        showDictionaryToggle: Bool = true,
        showUsageStatusPicker: Bool = true
    ) {
        self.service = service

        self.showNameSection = showNameSection
        self.showAPIKeySection = showAPIKeySection
        self.showEndpointSection = showEndpointSection
        self.showSupportedModelsSection = showSupportedModelsSection
        self.showUsedModelSection = showUsedModelSection
        self.showCustomPromptSection = showCustomPromptSection
        self.showTranslationToggle = showTranslationToggle
        self.showSentenceToggle = showSentenceToggle
        self.showDictionaryToggle = showDictionaryToggle
        self.showUsageStatusPicker = showUsageStatusPicker

        // Disable user to edit built-in supported models.
        self.isEditable = service.serviceType() != .builtInAI

        #if DEBUG
        self.isEditable = isEditable || Defaults[.enableBetaFeature]
        #endif
    }

    // MARK: Internal

    let service: LLMStreamService

    let showNameSection: Bool
    let showAPIKeySection: Bool
    let showEndpointSection: Bool
    let showSupportedModelsSection: Bool
    let showUsedModelSection: Bool
    let showCustomPromptSection: Bool
    let showTranslationToggle: Bool
    let showSentenceToggle: Bool
    let showDictionaryToggle: Bool
    let showUsageStatusPicker: Bool

    var isEditable = true

    var body: some View {
        ServiceConfigurationSecretSectionView(
            service: service,
            observeKeys: service.observeKeys
        ) {
            if showNameSection {
                InputCell(
                    textFieldTitleKey: "service.configuration.custom_openai.name.title",
                    key: service.nameKey,
                    placeholder: "custom_openai",
                    limitLength: 20
                )
            }

            if showAPIKeySection {
                SecureInputCell(
                    textFieldTitleKey: "service.configuration.openai.api_key.title",
                    key: service.apiKeyKey,
                    placeholder: service.apiKeyPlaceholder
                )
            }

            if showEndpointSection {
                SecureInputCell(
                    textFieldTitleKey: "service.configuration.openai.endpoint.title",
                    key: service.endpointKey,
                    placeholder: service.endpointPlaceholder,
                    showText: true
                )
            }

            if showSupportedModelsSection {
                TextEditorCell(
                    titleKey: "service.configuration.custom_openai.supported_models.title",
                    storedValueKey: service.supportedModelsKey,
                    placeholder: "service.configuration.custom_openai.model.placeholder",
                    alignment: .trailing,
                    minHeight: 55,
                    maxHeight: 100
                ).disabled(!isEditable)
            }

            if showUsedModelSection {
                PickerCell(
                    titleKey: "service.configuration.openai.model.title",
                    selectionKey: service.modelKey,
                    valuesKey: service.validModelsKey
                )
            }

            if showCustomPromptSection {
                ToggleCell(
                    titleKey: "service.configuration.openai.enable_custom_prompt.title",
                    key: service.enableCustomPromptKey,
                    footnote: "service.configuration.openai.enable_custom_prompt.footnote"
                )

                VStack(spacing: 5) {
                    // system prompt
                    TextEditorCell(
                        titleKey: "service.configuration.openai.system_prompt.title",
                        storedValueKey: service.systemPromptKey,
                        placeholder: "service.configuration.openai.system_prompt.placeholder",
                        height: 100
                    )

                    // user prompt
                    TextEditorCell(
                        titleKey: "service.configuration.openai.user_prompt.title",
                        storedValueKey: service.userPromptKey,
                        placeholder: "service.configuration.openai.user_prompt.placeholder",
                        footnote: "service.configuration.openai.user_prompt.footnote",
                        height: 120
                    )
                }
            }

            if showTranslationToggle {
                StringToggleCell(
                    titleKey: "service.configuration.openai.translation.title",
                    key: service.translationKey
                )
            }
            if showSentenceToggle {
                StringToggleCell(
                    titleKey: "service.configuration.openai.sentence.title",
                    key: service.sentenceKey
                )
            }
            if showDictionaryToggle {
                StringToggleCell(
                    titleKey: "service.configuration.openai.dictionary.title",
                    key: service.dictionaryKey
                )
            }

            if showUsageStatusPicker {
                StaticPickerCell(
                    titleKey: "service.configuration.openai.usage_status.title",
                    key: service.serviceUsageStatusKey,
                    values: ServiceUsageStatus.allCases
                )
            }
        }
    }
}
