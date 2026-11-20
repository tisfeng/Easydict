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
/// Hides API key, endpoint, model and think-tag sections
/// since they are not applicable to CLI tools.
struct CodexCLIServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: CodexService) {
        self.service = service
        self._accessMode = .init(service.accessModeKey)
        self._managedModel = .init(service.managedModelKey)
        self._managedEffort = .init(service.managedReasoningEffortKey)
        self._customModels = .init(service.managedCustomModelsKey)
        self._hiddenModels = .init(service.managedHiddenModelsKey)
        self._managedFastMode = .init(service.managedFastModeKey)
        self._localEffort = .init(service.reasoningEffortKey)
        self._localModel = .init(service.modelKey)
        CodexRequestCoordinator.shared.observe(uuid: service.uuid)
    }

    // MARK: Internal

    var body: some View {
        Section {
            if accessMode == .managed {
                CodexManagedAccountView(configuration: CodexServiceConfig(uuid: service.uuid))
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
                        titleKey: "service.codex_cli.mode.title", key: service.accessModeKey,
                        values: CodexAccessMode.allCases
                    )
                    Divider()
                    if accessMode == .managed {
                        CodexManagedModelPicker(
                            models: managedModels, selection: managedModelSelection, isBusy: account.isBusy
                        ) { model in
                            CodexServiceConfig(uuid: service.uuid).removeModel(model)
                            additionResult = nil
                            effortError = nil
                        }
                        effortPicker
                            .disabled(!isManagedModelSupported || account.isBusy)
                            .help("service.codex_cli.custom_models.verify_effort")
                        if let effortError { errorMessage(effortError) }
                        Divider()
                        customModelControls
                        Divider()
                        Toggle("service.codex_cli.fast_mode.title", isOn: $managedFastMode)
                        Text("service.codex_cli.fast_mode.description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        InputCell(
                            textFieldTitleKey: "service.configuration.codex_cli.model.title", key: service.modelKey,
                            placeholder: "service.configuration.codex_cli.model.placeholder"
                        )
                        effortPicker
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
            validationAction: accessMode == .managed ? validateManagedConnection : nil,
            validationDisabled: accessMode == .managed && !canValidateManagedConnection
        )
        .task(id: "\(accessMode.rawValue):\(localModel)") {
            guard accessMode == .localCLI else { return }
            let requestedModel = localModel
            do {
                let discovered = try await CodexAppServer.localCLI.availableLocalModels()
                try Task.checkCancellation()
                guard accessMode == .localCLI, localModel == requestedModel else { return }
                localModels = discovered
                localEffort = CodexServiceConfig.compatibleLocalEffort(
                    localEffort, model: localModel, models: discovered
                )
            } catch {
                guard !Task.isCancelled, accessMode == .localCLI, localModel == requestedModel else { return }
                // A failed scan must not advertise preset capabilities or change saved choices.
                localModels = []
            }
        }
    }

    // MARK: Private

    @ObservedObject private var account = CodexAccount.shared
    @ObservedObject private var component = CodexComponentManager.shared
    @State private var newModelID = ""
    @State private var additionResult: Result<(), Error>?
    @State private var effortError: String?
    @State private var localModels: [CodexAppServer.LocalModel] = []

    private let service: CodexService
    @Default private var accessMode: CodexAccessMode
    @Default private var managedModel: String
    @Default private var managedEffort: CodexReasoningEffort
    @Default private var localEffort: CodexReasoningEffort
    @Default private var localModel: String
    @Default private var customModels: [String]
    @Default private var hiddenModels: [String]
    @Default private var managedFastMode: Bool

    private var managedModels: [String] {
        CodexServiceConfig.models(customModels: customModels, hiddenModels: hiddenModels)
    }

    private var isCustomModel: Bool {
        CodexServiceConfig(uuid: service.uuid).isCustomModel
    }

    private var canValidateManagedConnection: Bool {
        component.isReady && !component.isBusy && account.isSignedIn && !account.isBusy
    }

    private var isManagedModelSupported: Bool {
        managedModels.contains(managedModel)
    }

    private var managedModelSelection: Binding<String?> {
        Binding(get: { isManagedModelSupported ? managedModel : nil }, set: { model in
            if let model { service.model = model }
        })
    }

    private var localEfforts: [CodexReasoningEffort] {
        CodexServiceConfig.reasoningEfforts(mode: .localCLI, model: localModel, localModels: localModels)
    }

    private var managedEfforts: [CodexReasoningEffort] {
        CodexServiceConfig.reasoningEfforts(mode: .managed, model: managedModel)
    }

    private var candidateModel: String { newModelID.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canAddModel: Bool {
        CodexModelCatalog.isValidModelID(candidateModel) && !managedModels.contains(candidateModel)
            && canValidateManagedConnection
    }

    private var effortPicker: some View {
        let managed = accessMode == .managed
        let options = managed ? managedEfforts : localEfforts
        let value = managed ? managedEffort : localEffort
        let selection = Binding<CodexReasoningEffort?>(get: { options.contains(value) ? value : nil }, set: { effort in
            guard let effort else { return }
            if managed { selectManagedEffort(effort) } else { localEffort = effort }
        })
        return Picker("service.configuration.codex_cli.reasoning_effort.title", selection: selection) {
            if selection.wrappedValue == nil {
                Text("service.codex_cli.managed.select_effort").tag(nil as CodexReasoningEffort?).disabled(true)
            }
            ForEach(options, id: \.self) { effort in
                Text(managed ? effortTitle(effort) : effort.title).tag(Optional(effort))
            }
        }
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
                errorMessage(error.localizedDescription)
            }
        }
    }

    private func errorMessage(_ message: String) -> some View {
        Text(verbatim: message)
            .font(.caption).foregroundStyle(.red).textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        let configuration = CodexServiceConfig(uuid: service.uuid)
        account.verify(.effort(effort), configuration: configuration) { result in
            switch result {
            case .success:
                guard configuration == CodexServiceConfig(uuid: service.uuid) else { return }
                managedEffort = effort
                CodexServiceConfig(uuid: service.uuid).rememberSuccessfulSelection()
            case let .failure(error):
                if !(error is CancellationError) { effortError = error.localizedDescription }
            }
        }
    }

    private func addModel() {
        guard canAddModel else { return }
        additionResult = nil
        let model = candidateModel
        let selectAddedModel = !isManagedModelSupported || !managedEfforts.contains(managedEffort)
        account.verify(.model(model), configuration: CodexServiceConfig(uuid: service.uuid)) { result in
            if case .success = result {
                newModelID = ""
                if selectAddedModel {
                    service.model = model
                    managedEffort = .default
                    CodexServiceConfig(uuid: service.uuid).rememberSuccessfulSelection()
                }
            }
            if case let .failure(error) = result, error is CancellationError { return }
            additionResult = result
        }
    }

    private func validateManagedConnection() {
        let configuration = CodexServiceConfig(uuid: service.uuid)
        guard configuration.mode == .managed, canValidateManagedConnection else { return }
        account.validate(configuration: configuration)
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
            let path = CodexCLIInstallation.detectBinaryPath()
            await MainActor.run { detectedPath = path }
        }
    }
}
