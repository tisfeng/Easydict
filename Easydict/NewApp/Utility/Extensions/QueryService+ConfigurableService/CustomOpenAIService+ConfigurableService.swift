//
//  CustomOpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/26.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation
import SwiftUI

// MARK: - CustomOpenAIService + ConfigurableService

@available(macOS 13.0, *)
extension CustomOpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.customOpenAIAPIKey, .customOpenAIEndPoint, .customOpenAIModelsAvailable]
        ) {
            CustomOpenAIServiceConfigurationView(service: self)
        }
    }
}

// MARK: - CustomOpenAIServiceConfigurationView

@available(macOS 13.0, *)
private struct CustomOpenAIServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: CustomOpenAIService) {
        self.service = service
        self._viewModel = .init(wrappedValue: CustomOpenAIViewModel(service: service))
    }

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
            "service.configuration.custom_openai.supported_models.title",
            text: viewModel.$availableModels ?? "",
            prompt: Text("service.configuration.custom_openai.model.placeholder")
        )
        .padding(10.0)
        .lineLimit(1 ... 3)
        Picker(
            "service.configuration.openai.model.title",
            selection: viewModel.$model
        ) {
            ForEach(viewModel.validModels, id: \.self) { value in
                Text(value)
            }
        }
        .padding(10.0)

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

    @StateObject private var viewModel: CustomOpenAIViewModel
}

// MARK: - CustomOpenAIViewModel

private class CustomOpenAIViewModel: ObservableObject {
    // MARK: Lifecycle

    init(service: CustomOpenAIService) {
        self.service = service
        cancellables.append(
            Defaults.publisher(.customOpenAIModel, options: [])
                .removeDuplicates()
                .sink { change in
                    print("serviceConfigChanged: \(change)")
                    self.serviceConfigChanged()
                }
        )
        cancellables.append(
            Defaults.publisher(.customOpenAIModelsAvailable)
                .removeDuplicates()
                .sink { _ in
                    self.modelsTextChanged()
                }
        )
    }

    // MARK: Internal

    let service: CustomOpenAIService

    @Default(.customOpenAIModel) var model
    @Default(.customOpenAIModelsAvailable) var availableModels

    @Published var validModels: [String] = []

    // MARK: Private

    private var cancellables: [AnyCancellable] = []

    private func modelsTextChanged() {
        guard let availableModels else { return }
        if availableModels.isEmpty {
            model = ""
            validModels = []
            return
        }
        validModels = availableModels.components(separatedBy: ",").filter { !$0.isEmpty }
        if validModels.count == 1 || !validModels.contains(model) {
            model = validModels[0]
        }
    }

    private func serviceConfigChanged() {
        let userInfo: [String: Any] = [
            EZWindowTypeKey: service.windowType.rawValue,
            EZServiceTypeKey: service.serviceType().rawValue,
        ]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
}