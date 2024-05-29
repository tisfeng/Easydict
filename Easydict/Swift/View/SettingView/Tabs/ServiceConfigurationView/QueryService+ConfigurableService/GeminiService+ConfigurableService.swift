//
//  GeminiService+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/31.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation
import SwiftUI

// MARK: - GeminiService + ConfigurableService

extension GeminiService: ConfigurableService {
    func configurationListItems() -> some View {
        GeminiServiceConfigurationView(service: self)
    }
}

// MARK: - GeminiServiceConfigurationView

private struct GeminiServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: GeminiService) {
        self.service = service
        self.viewModel = GeminiViewModel(service: service)
    }

    // MARK: Internal

    let service: GeminiService

    var body: some View {
        ServiceConfigurationSecretSectionView(
            service: service,
            observeKeys: [.geminiAPIKey, .geminiAvailableModels]
        ) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.openai.api_key.title",
                key: .geminiAPIKey,
                placeholder: "service.configuration.gemini.api_key.placeholder"
            )
            // supported models
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
                key: .geminiTranslation
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.sentence.title",
                key: .geminiSentence
            )
            ServiceConfigurationToggleCell(
                titleKey: "service.configuration.openai.dictionary.title",
                key: .geminiDictionary
            )
            ServiceConfigurationPickerCell(
                titleKey: "service.configuration.openai.usage_status.title",
                key: .geminiServiceUsageStatus,
                values: ServiceUsageStatus.allCases
            )
        }
        .onDisappear {
            viewModel.invalidate()
        }
    }

    // MARK: Private

    @ObservedObject private var viewModel: GeminiViewModel
}

// MARK: - GeminiViewModel

private class GeminiViewModel: ObservableObject {
    // MARK: Lifecycle

    init(service: GeminiService) {
        self.service = service
        Defaults.publisher(.geminiModel, options: [])
            .removeDuplicates()
            .sink { _ in
                self.modelChanged()
            }
            .store(in: &cancellables)
        Defaults.publisher(.geminiAvailableModels)
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { _ in
                self.modelsTextChanged()
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    let service: GeminiService

    @Default(.geminiModel) var model
    @Default(.geminiAvailableModels) var availableModels

    @Published var validModels: [String] = []

    func invalidate() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    private func modelChanged() {
        if !validModels.contains(model) {
            if model.isEmpty {
                availableModels = ""
            } else {
                if availableModels?.isEmpty == true {
                    availableModels = model
                } else {
                    availableModels = availableModels ?? ""
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

        Defaults[.geminiValidModels] = validModels
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

// MARK: - GeminiModel

// swiftlint:disable identifier_name
enum GeminiModel: String, CaseIterable {
    // Docs: https://ai.google.dev/gemini-api/docs/models/gemini

    // RPM: Requests per minute, TPM: Tokens per minute
    // RPD: Requests per day, TPD: Tokens per day
    case gemini1_0_pro = "gemini-1.0-pro" // Free 15 RPM/32,000 TPM, 1,500 RPD/46,080,000 TPD (n/a context length)
    case gemini1_5_flash = "gemini-1.5-flash" // Free 15 RPM/100million TPM, 1500 RPD/ n/a TPD  (1048k context length)
    case gemini1_5_pro = "gemini-1.5-pro" // Free 2 RPM/32,000 TPM, 50 RPD/46,080,000 TPD (1048k context length)
}

// MARK: EnumLocalizedStringConvertible

// swiftlint:enable identifier_name

extension GeminiModel: EnumLocalizedStringConvertible {
    var title: String {
        rawValue
    }
}

// MARK: Defaults.Serializable

extension GeminiModel: Defaults.Serializable {}
