//
//  CodexCLIServiceConfigurationView.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

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
    }

    // MARK: Internal

    var body: some View {
        Section {
            CodexCLIStatusRow()
        }

        // Model + reasoning-effort overrides. Empty model and `.default` effort
        // both fall back to whatever is configured in ~/.codex/config.toml,
        // so users only see the CLI's behaviour change when they opt in.
        Section {
            InputCell(
                textFieldTitleKey: "service.configuration.codex_cli.model.title",
                key: service.modelKey,
                placeholder: "service.configuration.codex_cli.model.placeholder"
            )
            StaticPickerCell(
                titleKey: "service.configuration.codex_cli.reasoning_effort.title",
                key: service.reasoningEffortKey,
                values: CodexReasoningEffort.allCases
            )
        }
        #if AGENT_CLI_DEBUG
        Section {
            Button("service.codex_cli.debug_log.show_window") {
                CodexCLIDebugWindowController.shared.toggle()
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
            showTemperatureSlider: false
        )
    }

    // MARK: Private

    private let service: CodexCLIService
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
