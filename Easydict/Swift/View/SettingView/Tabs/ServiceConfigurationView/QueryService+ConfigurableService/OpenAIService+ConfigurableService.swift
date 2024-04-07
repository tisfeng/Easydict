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

@available(macOS 13.0, *)
extension OpenAIService: ConfigurableService {
    func configurationListItems() -> some View {
        OpenAIServiceConfigurationView(service: self)
    }
}

// MARK: - OpenAIServiceConfigurationView

@available(macOS 13.0, *)
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

            // model
            TextField(
                "service.configuration.custom_openai.supported_models.title",
                text: viewModel.$availableModels ?? "",
                prompt: Text("service.configuration.custom_openai.model.placeholder")
            )
            .padding(10.0)
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
                values: OpenAIUsageStats.allCases
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
        cancellables.append(
            Defaults.publisher(.openAIModel, options: [])
                .removeDuplicates()
                .sink { _ in
                    self.serviceConfigChanged()
                }
        )
        cancellables.append(
            Defaults.publisher(.openAIAvailableModels)
                .removeDuplicates()
                .sink { _ in
                    self.modelsTextChanged()
                }
        )
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

    private var cancellables: [AnyCancellable] = []

    private func modelsTextChanged() {
        guard let availableModels else { return }
        if availableModels.isEmpty {
            model = ""
            validModels = []
            return
        }
        validModels = availableModels.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if validModels.count == 1 || !validModels.contains(model) {
            model = validModels[0]
        }

        Defaults[.openAIVaildModels] = validModels
    }

    private func serviceConfigChanged() {
        // Currently, user of low os versions may change OpenAI model using URL scheme, like easydict://writeKeyValue?EZOpenAIModelKey=gpt-4
        // In this case, model may not be included in validModels, we need to handle it.

        if !validModels.contains(model) {
            Defaults[.openAIAvailableModels] = "\(model), " + (availableModels ?? "")
        }

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
    // Docs: https://platform.openai.com/docs/models/gpt-3-5-turbo

    case gpt3_5_turbo = "gpt-3.5-turbo" // Currently points to gpt-3.5-turbo-0125.
    case gpt4_turbo_preview = "gpt-4-turbo-preview" // Currently points to gpt-4-0125-preview.
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

// MARK: - OpenAIUsageStats

enum OpenAIUsageStats: String, CaseIterable {
    case `default` = "0"
    case alwaysOff = "1"
    case alwaysOn = "2"
}

// MARK: EnumLocalizedStringConvertible

extension OpenAIUsageStats: EnumLocalizedStringConvertible {
    var title: String {
        switch self {
        case .default:
            NSLocalizedString(
                "service.configuration.openai.usage_status_default.title",
                bundle: .main,
                comment: ""
            )
        case .alwaysOff:
            NSLocalizedString(
                "service.configuration.openai.usage_status_always_off.title",
                bundle: .main,
                comment: ""
            )
        case .alwaysOn:
            NSLocalizedString(
                "service.configuration.openai.usage_status_always_on.title",
                bundle: .main,
                comment: ""
            )
        }
    }
}

// MARK: Defaults.Serializable

extension OpenAIUsageStats: Defaults.Serializable {}
