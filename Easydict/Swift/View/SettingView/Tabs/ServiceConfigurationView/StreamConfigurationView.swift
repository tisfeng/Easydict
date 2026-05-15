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
        service: StreamService,
        showCustomNameSection: Bool = false,
        showAPIKeySection: Bool = true,
        showEndpointSection: Bool = true,
        showSupportedModelsSection: Bool = true,
        showUsedModelSection: Bool = true,
        showCustomPromptSection: Bool = true,
        showTranslationToggle: Bool = true,
        showSentenceToggle: Bool = true,
        showDictionaryToggle: Bool = true,
        showUsageStatusPicker: Bool = true,
        showThinkTagContent: Bool = true,
        showTemperatureSlider: Bool = true,
        temperatureMaxValue: Double = 2,
        showStreamingToggle: Bool = false
    ) {
        self.service = service

        self.showCustomNameSection = showCustomNameSection
        self.showAPIKeySection = showAPIKeySection
        self.showEndpointSection = showEndpointSection
        self.showSupportedModelsSection = showSupportedModelsSection
        self.showUsedModelSection = showUsedModelSection
        self.showCustomPromptSection = showCustomPromptSection
        self.showTranslationToggle = showTranslationToggle
        self.showSentenceToggle = showSentenceToggle
        self.showDictionaryToggle = showDictionaryToggle
        self.showUsageStatusPicker = showUsageStatusPicker
        self.showThinkTagSection = showThinkTagContent
        self.showTemperatureSlider = showTemperatureSlider
        self.showStreamingToggle = showStreamingToggle
        self.temperatureMaxValue = temperatureMaxValue

        // Disable user to edit built-in supported models.
        self.isEditable = service.serviceType() != .builtInAI

        self._apiKey = .init(service.apiKeyKey)
        self._endpoint = .init(service.endpointKey)
        self._showCustomPromptTextEditor = .init(service.enableCustomPromptKey)
    }

    // MARK: Internal

    let service: StreamService

    let showCustomNameSection: Bool
    let showAPIKeySection: Bool
    let showEndpointSection: Bool
    let showSupportedModelsSection: Bool
    let showUsedModelSection: Bool
    let showCustomPromptSection: Bool
    let showTranslationToggle: Bool
    let showSentenceToggle: Bool
    let showDictionaryToggle: Bool
    let showUsageStatusPicker: Bool
    let showThinkTagSection: Bool
    let showTemperatureSlider: Bool
    let temperatureMaxValue: Double
    let showStreamingToggle: Bool

    var isEditable = true

    @Default var apiKey: String
    @Default var endpoint: String

    // show system prompt and user prompt, according to service.enableCustomPrompt
    @Default var showCustomPromptTextEditor: Bool

    var body: some View {
        ServiceConfigurationSecretSectionView(
            service: service,
            observeKeys: service.observeKeys
        ) {
            if showCustomNameSection {
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
                VStack(alignment: .trailing, spacing: 0) {
                    TextEditorCell(
                        titleKey: "service.configuration.custom_openai.supported_models.title",
                        storedValueKey: service.supportedModelsKey,
                        placeholder: "service.configuration.custom_openai.model.placeholder",
                        minHeight: 55,
                        maxHeight: 100
                    )
                    .disabled(!isEditable)

                    if canFetchModels {
                        Button {
                            isFetchModelsPresented = true
                        } label: {
                            Text(fetchModelsTitle)
                        }
                        .disabled(isFetchModelsDisabled)
                        .help(Text(fetchModelsHelp))
                        .padding(.trailing, 10)
                    }
                }
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

                if showCustomPromptTextEditor {
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

            if showThinkTagSection {
                ToggleCell(
                    titleKey: "service.configuration.openai.hide_think_tag_content.title",
                    key: service.thinkTagKey
                )
            }

            if showTemperatureSlider {
                SliderCell(
                    titleKey: "service.configuration.openai.temperature.title",
                    storedValueKey: service.temperatureKey,
                    maxValue: temperatureMaxValue
                )
            }

            if showStreamingToggle {
                ToggleCell(
                    titleKey: "service.configuration.custom_openai.enable_streaming.title",
                    key: service.enableStreamingKey,
                    footnote: "service.configuration.custom_openai.enable_streaming.footnote"
                )
            }
        }
        .sheet(isPresented: $isFetchModelsPresented) {
            if let remoteModelFetcher {
                RemoteModelsSheet(
                    titleKey: fetchModelsTitle,
                    existingModels: existingModelIDs,
                    fetchModels: {
                        try await remoteModelFetcher.fetchRemoteModelIDs()
                    },
                    onSave: updateModels
                )
            }
        }
    }

    // MARK: Private

    @State private var isFetchModelsPresented = false

    private var remoteModelFetcher: RemoteModelFetchable? {
        guard service.serviceType() != .gitHub else { return nil }
        return service as? RemoteModelFetchable
    }

    private var canFetchModels: Bool {
        isEditable && remoteModelFetcher != nil
    }

    private var isFetchModelsDisabled: Bool {
        guard remoteModelFetcher != nil else { return true }
        if !isEditable { return true }
        if service.apiKeyRequirement().needsUserProvidedKey, apiKey.trim().isEmpty {
            return true
        }
        return showEndpointSection && !isValidEndpoint(endpoint)
    }

    private var fetchModelsHelp: LocalizedStringKey {
        guard remoteModelFetcher != nil else {
            return "service.configuration.fetch_models.title"
        }
        if service.apiKeyRequirement().needsUserProvidedKey, apiKey.trim().isEmpty {
            return "missing_secret_key_error"
        }
        if showEndpointSection, !isValidEndpoint(endpoint) {
            return "parameter_error"
        }
        return fetchModelsTitle
    }

    private var fetchModelsTitle: LocalizedStringKey {
        service.serviceType() == .ollama
            ? "service.configuration.fetch_models.local_title"
            : "service.configuration.fetch_models.title"
    }

    private var existingModelIDs: [String] {
        let storedModels = Defaults[service.supportedModelsKey]
        return service.validModels(from: storedModels)
    }

    private func updateModels(remoteModelIDs: [String], selectedModelIDs: [String]) {
        var models = service.validModels(from: Defaults[service.supportedModelsKey])
        let remoteModels = Set(remoteModelIDs.map { $0.trim().lowercased() })
        let selectedModels = Set(selectedModelIDs.map { $0.trim().lowercased() })

        models = models.filter {
            let modelID = $0.trim().lowercased()
            return !remoteModels.contains(modelID) || selectedModels.contains(modelID)
        }

        var existingModels = Set(models.map { $0.trim().lowercased() })
        for modelID in selectedModelIDs where existingModels.insert(modelID.trim().lowercased()).inserted {
            models.append(modelID)
        }
        service.supportedModels = service.supportedModels(from: models)
    }

    private func isValidEndpoint(_ endpoint: String) -> Bool {
        URL(string: endpoint.trim())?.isValid == true
    }
}

// MARK: - RemoteModelsSheet

private struct RemoteModelsSheet: View {
    // MARK: Internal

    let titleKey: LocalizedStringKey
    let existingModels: [String]
    let fetchModels: () async throws -> [String]
    let onSave: ([String], [String]) -> ()

    var body: some View {
        VStack(spacing: 12) {
            Text(titleKey)
                .font(.headline)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !errorMessage.isEmpty {
                errorView
            } else {
                pickerView
            }

            HStack {
                Spacer()
                Button("cancel", role: .cancel) {
                    dismiss()
                }
                Button("ok") {
                    let remoteModelIDs = models.map(\.id)
                    let selectedModelIDs = remoteModelIDs.filter(selectedIDs.contains)
                    dismiss()
                    Task { @MainActor in
                        onSave(remoteModelIDs, selectedModelIDs)
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 520, height: 440)
        .task {
            await loadModels()
        }
    }

    // MARK: Private

    @Environment(\.dismiss) private var dismiss
    @State private var models: [RemoteModelRow] = []
    @State private var selectedIDs = Set<String>()
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage = ""

    private var filteredModels: [RemoteModelRow] {
        let query = searchText.trim()
        return query.isEmpty ? models : models.filter { $0.id.localizedCaseInsensitiveContains(query) }
    }

    private var selectableIDs: [String] {
        filteredModels.map(\.id)
    }

    private var isAllSelected: Bool {
        !selectableIDs.isEmpty && selectableIDs.allSatisfy(selectedIDs.contains)
    }

    private var pickerView: some View {
        VStack(spacing: 10) {
            TextField("service.configuration.fetch_models.search", text: $searchText)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button {
                    toggleSelectAll()
                } label: {
                    Text(
                        isAllSelected
                            ? LocalizedStringKey("service.configuration.fetch_models.deselect_all")
                            : LocalizedStringKey("service.configuration.fetch_models.select_all")
                    )
                }
                .disabled(selectableIDs.isEmpty)
                Spacer()
            }

            List(filteredModels) { model in
                Toggle(isOn: binding(for: model.id)) {
                    Text(model.id)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Text("api_error")
                .font(.headline)
            Text(errorMessage)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            Button("retry") {
                Task { await loadModels() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func binding(for modelID: String) -> Binding<Bool> {
        Binding {
            selectedIDs.contains(modelID)
        } set: { isSelected in
            if isSelected {
                selectedIDs.insert(modelID)
            } else {
                selectedIDs.remove(modelID)
            }
        }
    }

    private func toggleSelectAll() {
        if isAllSelected {
            selectableIDs.forEach { selectedIDs.remove($0) }
        } else {
            selectedIDs.formUnion(selectableIDs)
        }
    }

    @MainActor
    private func loadModels() async {
        isLoading = true
        errorMessage = ""
        selectedIDs.removeAll()

        do {
            let existingModelSet = Set(existingModels.map { $0.trim().lowercased() })
            models = try await fetchModels().map {
                RemoteModelRow(id: $0, exists: existingModelSet.contains($0.trim().lowercased()))
            }
            selectedIDs = Set(models.filter(\.exists).map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - RemoteModelRow

private struct RemoteModelRow: Identifiable {
    let id: String
    let exists: Bool
}
