//
//  ClaudeCodeServiceConfigurationView.swift
//  Easydict
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

// MARK: - ClaudeCodeServiceConfigurationView

/// Configuration view for the Claude Code translation service.
///
/// Hides API key, endpoint, model, temperature, and think-tag sections
/// since they are not applicable to CLI tools.
struct ClaudeCodeServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: StreamService) {
        self.service = service
    }

    // MARK: Internal

    var body: some View {
        // Status row: show whether the CLI is installed.
        // Section renders directly inside the outer Form provided by ServiceTab,
        // so no nested Form is needed here.
        Section {
            CLIStatusRow()
        }
        #if AGENT_CLI_DEBUG
        Section {
            Button("service.claude_code.debug_log.show_window") {
                ClaudeCodeDebugWindowController.shared.toggle()
            }
        }
        #endif
        // Reuse StreamConfigurationView for the remaining toggles/prompt sections.
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

    private let service: StreamService
}

// MARK: - CLIStatusRow

/// A row that shows whether the `claude` binary is detectable on this machine.
private struct CLIStatusRow: View {
    // MARK: Internal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("service.claude_code.name")
                    .font(.body)
                if let path = detectedPath {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("service.claude_code.risk_warning")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("service.claude_code.not_installed")
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
            let path = ClaudeCodeRunner.detectBinaryPath()
            await MainActor.run { detectedPath = path }
        }
    }
}
