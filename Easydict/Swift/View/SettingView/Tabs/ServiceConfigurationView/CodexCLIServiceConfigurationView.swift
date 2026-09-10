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
        self._localEffort = .init(service.reasoningEffortKey)
        CodexRequestCoordinator.shared.observe(uuid: service.uuid)
    }

    // MARK: Internal

    var body: some View {
        Section {
            if accessMode == .managed {
                CodexManagedAccountView(configuration: CodexServiceConfiguration(uuid: service.uuid))
                if !isManagedModelSupported || !managedEfforts.contains(managedEffort) {
                    Text("service.codex_cli.managed.unsupported_selection")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                CodexCLIStatusRow()
                if !localEfforts.contains(localEffort) {
                    Text("service.codex_cli.local.unsupported_effort")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }

        // Model + reasoning-effort overrides. Empty model and `.default` effort
        // both fall back to whatever is configured in ~/.codex/config.toml,
        // so users only see the CLI's behaviour change when they opt in.
        Section {
            DisclosureGroup("service.codex_cli.advanced") {
                StaticPickerCell(
                    titleKey: "service.codex_cli.mode.title",
                    key: service.accessModeKey,
                    values: CodexAccessMode.allCases
                )
                if accessMode == .managed {
                    Picker("service.configuration.codex_cli.model.title", selection: managedModelSelection) {
                        Text("service.codex_cli.managed.select_model").tag(nil as String?).disabled(true)
                        ForEach(CodexManagedRuntime.bundledModelNames, id: \.self) { model in
                            Text(verbatim: model).tag(Optional(model))
                        }
                    }
                    Picker(
                        "service.configuration.codex_cli.reasoning_effort.title",
                        selection: managedEffortSelection
                    ) {
                        Text("service.codex_cli.managed.select_effort").tag(nil as CodexReasoningEffort?).disabled(true)
                        ForEach(managedEfforts, id: \.self) { effort in
                            Text(effort == .default ? "service.codex_cli.managed.reasoning_default" : effort.title)
                                .tag(Optional(effort))
                        }
                    }
                    .disabled(!isManagedModelSupported)
                } else {
                    InputCell(
                        textFieldTitleKey: "service.configuration.codex_cli.model.title",
                        key: service.modelKey,
                        placeholder: "service.configuration.codex_cli.model.placeholder"
                    )
                    Picker("service.configuration.codex_cli.reasoning_effort.title", selection: localEffortSelection) {
                        Text("service.codex_cli.managed.select_effort").tag(nil as CodexReasoningEffort?).disabled(true)
                        ForEach(localEfforts, id: \.self) { effort in
                            Text(effort.title).tag(Optional(effort))
                        }
                    }
                }
            }
        }
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

    private let service: CodexCLIService
    @Default private var accessMode: CodexAccessMode
    @Default private var managedModel: String
    @Default private var managedEffort: CodexReasoningEffort
    @Default private var localEffort: CodexReasoningEffort

    private var isManagedModelSupported: Bool {
        CodexManagedRuntime.bundledModelNames.contains(managedModel)
    }

    private var managedModelSelection: Binding<String?> {
        Binding(get: { isManagedModelSupported ? managedModel : nil }, set: { model in
            if let model { managedModel = model }
        })
    }

    private var managedEffortSelection: Binding<CodexReasoningEffort?> {
        Binding(get: { managedEfforts.contains(managedEffort) ? managedEffort : nil }, set: { effort in
            if let effort { managedEffort = effort }
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
