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

// MARK: - CustomOpenAIService + ConfigurableService

@available(macOS 13.0, *)
extension CustomOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.customOpenAIAPIKey, .customOpenAIEndPoint]
        ) {
            CustomOpenAIServiceConfigurationView(service: self)
        }
    }
}

// MARK: - CustomOpenAIServiceConfigurationView

@available(macOS 13.0, *)
private struct CustomOpenAIServiceConfigurationView: View {
    // MARK: Internal

    let service: CustomOpenAIService

    var body: some View {
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
        TextField(
            "service.configuration.custom_openai.allmodels.title",
            text: $availableModels,
            prompt: Text("service.configuration.custom_openai.model.placeholder")
        )
        .padding(10.0)
        .lineLimit(1 ... 3)
        .onChange(of: availableModels, perform: { newValue in
            modelsTextChanged(newValue)
        })
        Picker(
            "service.configuration.openai.model.title",
            selection: $model
        ) {
            ForEach(availableModels.components(separatedBy: ","), id: \.self) { value in
                Text(value)
            }
        }
        .padding(10.0)
        .onChange(of: model) { _ in
            modelSelectionChanged()
        }

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

    // MARK: Private

    @Default(.customOpenAIModel) private var model
    @Default(.customOpenAIModelsAvailable) private var availableModels

    private func modelSelectionChanged() {
        let userInfo: [String: Any] = [EZWindowTypeKey: service.windowType.rawValue]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }

    private func modelsTextChanged(_ newValue: String) {
        if newValue.isEmpty {
            availableModels = CustomOpenAIService.defaultModels.joined(separator: ",")
        }
        let models = availableModels.components(separatedBy: ",")
        if !models.contains(model) {
            model = models[0]
        }
    }
}
