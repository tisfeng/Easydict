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
                stringDefaultsKey(.supportedModels),
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
                    titleKey: "service.configuration.custom_openai.supported_models.title",
                    storedValueKey: stringDefaultsKey(.supportedModels),
                    placeholder: "service.configuration.custom_openai.model.placeholder"
                )
            }

            if showUsedModelSection {
                ServiceConfigurationPickerCell(
                    titleKey: "service.configuration.openai.model.title",
                    key: stringDefaultsKey(.model),
                    values: viewModel.validModels
                )
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
        service: LLMStreamService,
        model: String,
        supportedModels: String
    ) {
        self.service = service
        self.model = model
        self.supportedModels = supportedModels

        setupSubscribers()
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

    @Published var supportedModels: String {
        didSet {
            if supportedModels != oldValue {
                supportedModelsTextDidChanged(supportedModels)
            }
        }
    }

    func setupSubscribers() {
        Defaults.publisher(stringDefaultsKey(.name), options: [])
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                self?.notifyServiceConfigurationChanged()
            }
            .store(in: &cancellables)

        Defaults.publisher(stringDefaultsKey(.model), options: [])
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.modelDidChanged($0.newValue)
            }
            .store(in: &cancellables)

        Defaults.publisher(stringDefaultsKey(.supportedModels))
            .removeDuplicates()
            .throttle(for: 0.1, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] in
                self?.supportedModelsTextDidChanged($0.newValue)
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

    private func modelDidChanged(_ newModel: String) {
        Defaults[stringDefaultsKey(.model)] = newModel

        // Handle some special cases
        if !validModels.contains(newModel) {
            if newModel.isEmpty {
                supportedModels = ""
            } else {
                if supportedModels.isEmpty {
                    supportedModels = newModel
                } else {
                    supportedModels = "\(newModel), " + supportedModels
                }
            }
        }
        notifyServiceConfigurationChanged()
    }

    private func supportedModelsTextDidChanged(_ newSupportedModels: String) {
        Defaults[stringDefaultsKey(.supportedModels)] = newSupportedModels

        validModels = newSupportedModels.components(separatedBy: ",")
            .map { $0.trim() }.filter { !$0.isEmpty }

        if validModels.isEmpty {
            model = ""
        } else if !validModels.contains(model) {
            model = validModels[0]
        }
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
