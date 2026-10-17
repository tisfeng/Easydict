//
//  CodexCLIServiceConfigurationView.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import SFSafeSymbols
import SwiftUI

// MARK: - CodexCLIServiceConfigurationView

/// Configuration view for the Codex CLI translation service.
///
/// Hides API key, endpoint, model, temperature, and think-tag sections
/// since they are not applicable to CLI tools.
struct CodexCLIServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: CodexCLIService) {
        self.service = service
        self._accessMode = .init(service.accessModeKey)
        self._managedModel = .init(service.managedModelKey)
        self._managedEffort = .init(service.managedReasoningEffortKey)
        self._customModels = .init(service.managedCustomModelsKey)
        self._hiddenModels = .init(service.managedHiddenModelsKey)
        self._managedFastMode = .init(service.managedFastModeKey)
        self._localEffort = .init(service.reasoningEffortKey)
        CodexRequestCoordinator.shared.observe(uuid: service.uuid)
    }

    // MARK: Internal

    var body: some View {
        Section {
            if accessMode == .managed {
                CodexManagedAccountView(configuration: CodexServiceConfiguration(uuid: service.uuid))
                if !managedModel.isEmpty, !isManagedModelSupported || !managedEfforts.contains(managedEffort) {
                    Text("service.codex_cli.managed.unsupported_selection")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } else {
                CodexCLIStatusRow()
                if !localEfforts.contains(localEffort) {
                    Text("service.codex_cli.local.unsupported_effort")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }

        // Managed `.default` effort uses the selected model's catalog default.
        // Local CLI empty/default values defer to ~/.codex/config.toml instead.
        Section {
            DisclosureGroup("service.codex_cli.advanced") {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    StaticPickerCell(
                        titleKey: "service.codex_cli.mode.title",
                        key: service.accessModeKey,
                        values: CodexAccessMode.allCases
                    )
                    Divider()
                    if accessMode == .managed {
                        if CodexRuntimeRelease.current == .modern {
                            CodexManagedModelPicker(
                                models: managedModels, selection: managedModelSelection, isBusy: account.isBusy
                            ) { model in
                                CodexServiceConfiguration(uuid: service.uuid).removeModel(model)
                                additionResult = nil
                                effortError = nil
                            }
                        } else {
                            Picker("service.configuration.codex_cli.model.title", selection: managedModelSelection) {
                                if managedModelSelection.wrappedValue == nil {
                                    Text("service.codex_cli.custom_models.select_model")
                                        .tag(nil as String?).disabled(true)
                                }
                                ForEach(managedModels, id: \.self) { model in
                                    Text(verbatim: model).tag(Optional(model))
                                }
                            }
                        }
                        Picker(
                            "service.configuration.codex_cli.reasoning_effort.title",
                            selection: managedEffortSelection
                        ) {
                            if managedEffortSelection.wrappedValue == nil {
                                Text("service.codex_cli.managed.select_effort")
                                    .tag(nil as CodexReasoningEffort?)
                                    .disabled(true)
                            }
                            ForEach(managedEfforts, id: \.self) { effort in
                                Text(effortTitle(effort))
                                    .tag(Optional(effort))
                            }
                        }
                        .disabled(!isManagedModelSupported || account.isBusy)
                        .help("service.codex_cli.custom_models.verify_effort")
                        if let effortError {
                            Text(verbatim: effortError)
                                .font(.caption).foregroundStyle(.red).textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        if CodexRuntimeRelease.current == .modern {
                            Divider()
                            customModelControls
                        }
                        Divider()
                        Toggle("service.codex_cli.fast_mode.title", isOn: $managedFastMode)
                        Text("service.codex_cli.fast_mode.description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        InputCell(
                            textFieldTitleKey: "service.configuration.codex_cli.model.title",
                            key: service.modelKey,
                            placeholder: "service.configuration.codex_cli.model.placeholder"
                        )
                        Picker(
                            "service.configuration.codex_cli.reasoning_effort.title",
                            selection: localEffortSelection
                        ) {
                            if localEffortSelection.wrappedValue == nil {
                                Text("service.codex_cli.managed.select_effort")
                                    .tag(nil as CodexReasoningEffort?)
                                    .disabled(true)
                            }
                            ForEach(localEfforts, id: \.self) { effort in
                                Text(effort.title).tag(Optional(effort))
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .onChange(of: managedModel) { _ in effortError = nil }
        .onChange(of: accessMode) { _ in effortError = nil }
        #if AGENT_CLI_DEBUG
        if accessMode == .localCLI {
            Section {
                Button("service.codex_cli.debug_log.show_window") {
                    CodexCLIDebugWindowController.shared.toggle()
                }
            }
        }
        #endif
        StreamConfigurationView(
            service: service,
            showAPIKeySection: false,
            showEndpointSection: false,
            showSupportedModelsSection: false,
            showUsedModelSection: false,
            showThinkTagContent: false,
            showTemperatureSlider: false,
            showValidationButton: accessMode == .localCLI
        )
    }

    // MARK: Private

    @ObservedObject private var account = CodexManagedAccount.shared
    @ObservedObject private var component = CodexComponentManager.shared
    @State private var newModelID = ""
    @State private var additionResult: Result<(), Error>?
    @State private var effortError: String?

    private let service: CodexCLIService
    @Default private var accessMode: CodexAccessMode
    @Default private var managedModel: String
    @Default private var managedEffort: CodexReasoningEffort
    @Default private var managedFastMode: Bool
    @Default private var localEffort: CodexReasoningEffort
    @Default private var customModels: [String]
    @Default private var hiddenModels: [String]

    private var managedModels: [String] {
        let hidden = Set(hiddenModels)
        let saved = customModels.filter { CodexModelCatalog.isValidModelID($0) }
        let models = CodexManagedRuntime.bundledModelNames
            + (CodexRuntimeRelease.current == .modern
                ? saved.filter { !CodexManagedRuntime.bundledModelNames.contains($0) } : [])
        return CodexRuntimeRelease.current == .modern ? models.filter { !hidden.contains($0) } : models
    }

    private var isCustomModel: Bool {
        customModels.contains(managedModel) && !CodexManagedRuntime.bundledModelNames.contains(managedModel)
    }

    private var isManagedModelSupported: Bool {
        managedModels.contains(managedModel)
    }

    private var managedModelSelection: Binding<String?> {
        Binding(get: { isManagedModelSupported ? managedModel : nil }, set: { model in
            if let model { service.model = model }
        })
    }

    private var managedEffortSelection: Binding<CodexReasoningEffort?> {
        Binding(get: { managedEfforts.contains(managedEffort) ? managedEffort : nil }, set: { effort in
            if let effort { selectManagedEffort(effort) }
        })
    }

    private var localEfforts: [CodexReasoningEffort] {
        CodexServiceConfiguration.reasoningEfforts(mode: .localCLI, model: "")
    }

    private var localEffortSelection: Binding<CodexReasoningEffort?> {
        Binding(get: { localEfforts.contains(localEffort) ? localEffort : nil }, set: { effort in
            if let effort { localEffort = effort }
        })
    }

    private var managedEfforts: [CodexReasoningEffort] {
        CodexServiceConfiguration.reasoningEfforts(mode: .managed, model: managedModel)
    }

    private var candidateModel: String { newModelID.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canAddModel: Bool {
        CodexModelCatalog.isValidModelID(candidateModel) && !managedModels.contains(candidateModel)
            && !account.isBusy && account.isSignedIn && component.isReady
    }

    @ViewBuilder private var customModelControls: some View {
        HStack {
            Text("service.codex_cli.custom_models.model_id")
            Spacer()
            CodexModelIDField(text: $newModelID, isEnabled: !account.isBusy, onSubmit: addModel)
                .frame(maxWidth: 280)
                .frame(height: 24)
                .onChange(of: newModelID) { value in
                    if !value.isEmpty, additionResult != nil { additionResult = nil }
                }
            Button("service.codex_cli.custom_models.add_and_verify") { addModel() }
                .disabled(!canAddModel)
        }
        Text("service.codex_cli.custom_models.description")
            .font(.caption).foregroundStyle(.secondary)
        if !candidateModel.isEmpty, managedModels.contains(candidateModel) {
            Text("service.codex_cli.custom_models.duplicate")
                .font(.caption).foregroundStyle(.secondary)
        } else if !candidateModel.isEmpty, !CodexModelCatalog.isValidModelID(candidateModel) {
            Text("service.codex_cli.custom_models.invalid_id")
                .font(.caption).foregroundStyle(.red)
        }
        if let additionResult {
            switch additionResult {
            case .success:
                Text("service.codex_cli.custom_models.added")
                    .font(.caption).foregroundStyle(.green)
            case let .failure(error):
                Text(verbatim: error.localizedDescription)
                    .font(.caption).foregroundStyle(.red).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func effortTitle(_ effort: CodexReasoningEffort) -> LocalizedStringKey {
        guard effort == .default else { return effort.title }
        return isCustomModel ? "service.codex_cli.custom_models.automatic"
            : "service.codex_cli.managed.reasoning_default"
    }

    private func selectManagedEffort(_ effort: CodexReasoningEffort) {
        guard effort != managedEffort, !account.isBusy else { return }
        effortError = nil
        guard isCustomModel, effort != .default else {
            managedEffort = effort
            return
        }
        let configuration = CodexServiceConfiguration(uuid: service.uuid)
        account.verifyCustomEffort(effort, configuration: configuration) { result in
            switch result {
            case .success:
                guard configuration == CodexServiceConfiguration(uuid: service.uuid) else { return }
                managedEffort = effort
                CodexServiceConfiguration(uuid: service.uuid).rememberSuccessfulSelection()
            case let .failure(error):
                if !(error is CancellationError) { effortError = error.localizedDescription }
            }
        }
    }

    private func addModel() {
        guard canAddModel else { return }
        additionResult = nil
        let model = candidateModel
        let selectAddedModel = !isManagedModelSupported
        account.addCustomModel(model, configuration: CodexServiceConfiguration(uuid: service.uuid)) { result in
            if case .success = result {
                newModelID = ""
                if selectAddedModel {
                    service.model = model
                    managedEffort = .default
                }
            }
            if case let .failure(error) = result, error is CancellationError { return }
            additionResult = result
        }
    }
}

// MARK: - CodexCLIStatusRow

/// A row that shows whether the `codex` binary is detectable on this machine.
private struct CodexCLIStatusRow: View {
    // MARK: Internal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("service.codex_cli.name")
                    .font(.body)
                if let path = detectedPath {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("service.codex_cli.risk_warning")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("service.codex_cli.not_installed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if detectedPath != nil {
                Image(systemSymbol: .checkmarkCircleFill)
                    .foregroundStyle(.green)
            } else {
                Image(systemSymbol: .xmarkCircleFill)
                    .foregroundStyle(.red)
            }
        }
        .onAppear { detect() }
    }

    // MARK: Private

    @State private var detectedPath: String?

    private func detect() {
        Task.detached(priority: .utility) {
            let path = CodexCLIRunner.detectBinaryPath()
            await MainActor.run { detectedPath = path }
        }
    }
}
