//
//  OpenAIService+ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation
import SwiftUI

// MARK: - OpenAIService + ConfigurableService

extension OpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        OpenAIServiceConfigurationView(service: self)
    }
}

// MARK: - OpenAIServiceConfigurationView

private struct OpenAIServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: OpenAIService) {
        self.service = service
        self.viewModel = OpenAIServiceViewModel(service: service)
    }

    // MARK: Internal

    let service: OpenAIService

    var body: some View {
        ServiceConfigurationSecretSectionView(
            service: service, observeKeys: [.openAIAPIKey, .openAIEndPoint, .openAIAvailableModels]
        ) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .openAIAPIKey,
                placeholder: "service.configuration.openai.api_key.placeholder"
            )
            // endpoint
            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.openai.endpoint.title",
                key: .openAIEndPoint,
                placeholder: "service.configuration.openai.endpoint.placeholder"
            )

            // models
            TextEditorCell(
                title: "service.configuration.custom_openai.supported_models.title",
                text: viewModel.$availableModels ?? "",
                placeholder: "service.configuration.custom_openai.model.placeholder"
            )

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
                key: .openAITranslation
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.sentence.title",
                key: .openAISentence
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.dictionary.title",
                key: .openAIDictionary
            )
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.usage_status.title",
                key: .openAIServiceUsageStatus,
                values: ServiceUsageStatus.allCases
            )
        }
        .onDisappear {
            viewModel.invalidate()
        }
    }

    // MARK: Private

    @ObservedObject private var viewModel: OpenAIServiceViewModel
}

// MARK: - OpenAIServiceViewModel

private class OpenAIServiceViewModel: ObservableObject {
    // MARK: Lifecycle

    init(service: OpenAIService) {
        self.service = service
        Defaults.publisher(.openAIModel, options: [])
            .removeDuplicates()
            .sink { _ in
                self.modelChanged()
            }
            .store(in: &cancellables)
        Defaults.publisher(.openAIAvailableModels)
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { _ in
                self.modelsTextChanged()
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    let service: OpenAIService

    @Default(.openAIModel) var model
    @Default(.openAIAvailableModels) var availableModels

    @Published var validModels: [String] = []

    func invalidate() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    private func modelChanged() {
        // Currently, user of low os versions can change OpenAI model using URL scheme, like easydict://writeKeyValue?EZOpenAIModelKey=gpt-4
        // In this case, model may not be included in validModels, we need to handle it.

        if !validModels.contains(model) {
            if model.isEmpty {
                availableModels = ""
            } else {
                if availableModels?.isEmpty == true {
                    availableModels = model
                } else {
                    availableModels = "\(model), " + (availableModels ?? "")
                }
            }
        }

        serviceConfigChanged()
    }

    private func modelsTextChanged() {
        guard let availableModels else { return }

        validModels = availableModels.components(separatedBy: ",")
            .map { $0.trim() }.filter { !$0.isEmpty }

        if validModels.isEmpty {
            model = ""
        } else if !validModels.contains(model) {
            model = validModels[0]
        }

        Defaults[.openAIVaildModels] = validModels
    }

    private func serviceConfigChanged() {
        objectWillChange.send()

        let userInfo: [String: Any] = [
            EZWindowTypeKey: service.windowType.rawValue,
            EZServiceTypeKey: service.serviceType().rawValue,
        ]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
}

// MARK: - EnumLocalizedStringConvertible

protocol EnumLocalizedStringConvertible {
    var title: String { get }
}

// MARK: - OpenAIModel

// swiftlint:disable identifier_name
enum OpenAIModel: String, CaseIterable {
    // Docs: https://platform.openai.com/docs/models

    case gpt3_5_turbo = "gpt-3.5-turbo" // Currently points to gpt-3.5-turbo-0125. Input: $0.50 | Output: $1.50  (16k)
    case gpt4_turbo = "gpt-4-turbo" // Currently points to gpt-4-turbo-2024-04-09. Input: $10 | Output: $30  (128k)
    case gpt4o = "gpt-4o" // Currently points to gpt-4o-2024-05-13. Input: $5 | Output: $15  (128k context length)
}

// MARK: EnumLocalizedStringConvertible

// swiftlint:enable identifier_name

extension OpenAIModel: EnumLocalizedStringConvertible {
    var title: String {
        rawValue
    }
}

// MARK: Defaults.Serializable

extension OpenAIModel: Defaults.Serializable {}
