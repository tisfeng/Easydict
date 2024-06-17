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

struct StreamConfigurationView: View, DefaultsKey {
    // MARK: Lifecycle

    init(
        service: LLMStreamService,
        viewModel: LLMStreamViewModel,
        showNameSection: Bool = false,
        showAPIKeySection: Bool = true,
        showEndpointSection: Bool = true,
        showSupportedModelsSection: Bool = true,
        showUsedModelSection: Bool = true,
        showTranslationToggle: Bool = true,
        showSentenceToggle: Bool = true,
        showDictionaryToggle: Bool = true,
        showUsageStatusPicker: Bool = true
    ) {
        self.service = service
        self.viewModel = viewModel

        self.showNameSection = showNameSection
        self.showAPIKeySection = showAPIKeySection
        self.showEndpointSection = showEndpointSection
        self.showSupportedModelsSection = showSupportedModelsSection
        self.showUsedModelSection = showUsedModelSection
        self.showTranslationToggle = showTranslationToggle
        self.showSentenceToggle = showSentenceToggle
        self.showDictionaryToggle = showDictionaryToggle
        self.showUsageStatusPicker = showUsageStatusPicker
    }

    // MARK: Internal

    let service: LLMStreamService
    @ObservedObject var viewModel: LLMStreamViewModel

    let showNameSection: Bool
    let showAPIKeySection: Bool
    let showEndpointSection: Bool
    let showSupportedModelsSection: Bool
    let showUsedModelSection: Bool
    let showTranslationToggle: Bool
    let showSentenceToggle: Bool
    let showDictionaryToggle: Bool
    let showUsageStatusPicker: Bool

    var body: some View {
        ServiceConfigurationSecretSectionView(
            service: service,
            observeKeys: [
                stringDefaultsKey(.apiKey),
                stringDefaultsKey(.endpoint),
                stringDefaultsKey(.availableModels),
            ]
        ) {
            if showNameSection {
                ServiceConfigurationInputCell(
                    textFieldTitleKey: "service.configuration.custom_openai.name.title",
                    key: stringDefaultsKey(.name),
                    placeholder: "custom_openai",
                    limitLength: 20
                )
            }

            if showAPIKeySection {
                ServiceConfigurationSecureInputCell(
                    textFieldTitleKey: "service.configuration.openai.api_key.title",
                    key: stringDefaultsKey(.apiKey),
                    placeholder: "service.configuration.openai.api_key.placeholder"
                )
            }

            if showEndpointSection {
                ServiceConfigurationInputCell(
                    textFieldTitleKey: "service.configuration.openai.endpoint.title",
                    key: stringDefaultsKey(.endpoint),
                    placeholder: "service.configuration.openai.endpoint.placeholder"
                )
            }

            if showSupportedModelsSection {
                TextEditorCell(
                    title: "service.configuration.custom_openai.supported_models.title",
                    text: $viewModel.availableModels,
                    placeholder: "service.configuration.custom_openai.model.placeholder"
                ).onChange(of: viewModel.availableModels) {
                    print("onChange availableModels: \($0)")
                }
            }

            if showUsedModelSection {
                Picker(
                    "service.configuration.openai.model.title",
                    selection: $viewModel.model
                ) {
                    ForEach(viewModel.validModels, id: \.self) { value in
                        Text(value)
                    }
                }
                .padding(10.0)
                .onChange(of: viewModel.model) {
                    print("onChange model: \($0)")
                }
            }

            if showTranslationToggle {
                ServiceConfigurationToggleCell(
                    titleKey: "service.configuration.openai.translation.title",
                    key: stringDefaultsKey(.translation)
                )
            }
            if showSentenceToggle {
                ServiceConfigurationToggleCell(
                    titleKey: "service.configuration.openai.sentence.title",
                    key: stringDefaultsKey(.sentence)
                )
            }
            if showDictionaryToggle {
                ServiceConfigurationToggleCell(
                    titleKey: "service.configuration.openai.dictionary.title",
                    key: stringDefaultsKey(.dictionary)
                )
            }

            if showUsageStatusPicker {
                ServiceConfigurationPickerCell(
                    titleKey: "service.configuration.openai.usage_status.title",
                    key: serviceDefaultsKey(.serviceUsageStatus, defaultValue: ServiceUsageStatus.default),
                    values: ServiceUsageStatus.allCases
                )
            }
        }
        .onDisappear {
            service.invalidate()
        }
    }

    func stringDefaultsKey(_ key: StoredKey) -> Defaults.Key<String> {
        service.stringDefaultsKey(key)
    }

    func serviceDefaultsKey<T>(_ key: StoredKey, defaultValue: T) -> Defaults.Key<T> {
        service.serviceDefaultsKey(key, defaultValue: defaultValue)
    }
}

// MARK: - LLMStreamViewModel

class LLMStreamViewModel: ObservableObject, DefaultsKey {
    // MARK: Lifecycle

    init(
        service: LLMStreamService
//        model: String,
//        availableModels: String
    ) {
        self.service = service
//        self.model = model
//        self.availableModels = availableModels

        self.model = Defaults[service.stringDefaultsKey(.model)]
        self.availableModels = Defaults[service.stringDefaultsKey(.availableModels)]

        setupSubscribers()

        availableModelsTextDidChanged(availableModels)
    }

    // MARK: Internal

    let service: LLMStreamService

    @Published var validModels: [String] = []

    @Published var model: String {
        didSet {
            if model != oldValue {
                modelDidChanged(model)
            }
        }
    }

    @Published var availableModels: String {
        didSet {
            if availableModels != oldValue {
                availableModelsTextDidChanged(availableModels)
            }
        }
    }

    func setupSubscribers() {
        Defaults.publisher(stringDefaultsKey(.model))
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.model = $0.newValue
            }
            .store(in: &cancellables)

        Defaults.publisher(stringDefaultsKey(.availableModels))
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.availableModels = $0.newValue
            }
            .store(in: &cancellables)
    }

    func serviceDefaultsKey<T>(_ key: StoredKey, defaultValue: T) -> Defaults.Key<T> {
        service.serviceDefaultsKey(key, defaultValue: defaultValue)
    }

    func stringDefaultsKey(_ key: StoredKey) -> Defaults.Key<String> {
        service.stringDefaultsKey(key)
    }

    func invalidate() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    private func modelDidChanged(_ model: String) {
        Defaults[stringDefaultsKey(.model)] = model

        if !validModels.contains(model) {
            if model.isEmpty {
                availableModels = ""
            } else {
                if availableModels.isEmpty {
                    availableModels = model
                } else {
                    availableModels = "\(model), " + availableModels
                }
            }
        }
        notifyServiceConfigurationChanged()
    }

    private func availableModelsTextDidChanged(_ availableModels: String) {
        Defaults[stringDefaultsKey(.availableModels)] = availableModels

        validModels = availableModels.components(separatedBy: ",")
            .map { $0.trim() }.filter { !$0.isEmpty }

        if validModels.isEmpty {
            model = ""
        } else if !validModels.contains(model) {
            model = validModels[0]
        }
        Defaults[serviceDefaultsKey(.validModels, defaultValue: [""])] = validModels
    }

    private func notifyServiceConfigurationChanged() {
        objectWillChange.send()

        let userInfo: [String: Any] = [
            EZWindowTypeKey: service.windowType.rawValue,
            EZServiceTypeKey: service.serviceType().rawValue,
        ]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
}
