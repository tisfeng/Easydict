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
                ServiceConfigurationInputCell(
                    textFieldTitleKey: "service.configuration.custom_openai.name.title",
                    key: service.nameKey,
                    placeholder: "custom_openai",
                    limitLength: 20
                )
            }

            if showAPIKeySection {
                ServiceConfigurationSecureInputCell(
                    textFieldTitleKey: "service.configuration.openai.api_key.title",
                    key: service.apiKeyKey,
                    placeholder: service.apiKeyPlaceholder
                )
            }

            if showEndpointSection {
                ServiceConfigurationSecureInputCell(
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
                    placeholder: "service.configuration.custom_openai.model.placeholder"
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
                    detailText: "service.configuration.openai.enable_custom_prompt.detail"
                )

                TextEditorCell(
                    titleKey: "service.configuration.openai.custom_prompt.title",
                    storedValueKey: service.customPromptKey,
                    placeholder: "service.configuration.openai.custom_prompt.placeholder",
                    detailText: "service.configuration.openai.custom_prompt.detail"
                )
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
                ServiceConfigurationPickerCell(
                    titleKey: "service.configuration.openai.usage_status.title",
                    key: service.serviceUsageStatusKey,
                    values: ServiceUsageStatus.allCases
                )
            }
        }
    }
}
