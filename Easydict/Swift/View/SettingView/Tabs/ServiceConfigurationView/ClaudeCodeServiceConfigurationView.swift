//
//  ClaudeCodeServiceConfigurationView.swift
//  Easydict
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import SFSafeSymbols
import SwiftUI

// MARK: - ClaudeCodeServiceConfigurationView

/// Configuration view for the Claude Code translation service.
///
/// Hides API key, endpoint, model, temperature, and think-tag sections
/// since they are not applicable to CLI tools.
struct ClaudeCodeServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: ClaudeCodeService) {
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

        // Model override. Accepts an alias (sonnet, opus, haiku) or a full model
        // name; clearing the field falls back to the CLI's own default model.
        // The placeholder interpolates the app default so users can see what to
        // type to restore it after clearing the field.
        Section {
            ModelInputRow(key: service.modelKey)
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

    private let service: ClaudeCodeService
}

// MARK: - ModelInputRow

/// The model text field with an info button that explains the accepted formats.
///
/// The Claude CLI only accepts short aliases (`sonnet`, `opus`, `haiku`) or full
/// model IDs (`claude-opus-4-7`); shorthand like `opus4.7` fails at query time,
/// so the popover documents the valid formats up front.
private struct ModelInputRow: View {
    // MARK: Lifecycle

    init(key: Defaults.Key<String>) {
        _model = .init(key)
    }

    // MARK: Internal

    var body: some View {
        LabeledContent {
            TextField(
                text: $model,
                prompt: Text(
                    "service.configuration.claude_code.model.placeholder \(ClaudeCodeRunner.defaultModel)"
                )
            ) {
                EmptyView()
            }
            .multilineTextAlignment(.trailing)
        } label: {
            HStack(spacing: 4) {
                Text("service.configuration.claude_code.model.title")
                Button {
                    isShowingHelp.toggle()
                } label: {
                    Image(systemSymbol: .infoCircle)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isShowingHelp, arrowEdge: .bottom) {
                    Text("service.configuration.claude_code.model.help")
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .frame(width: 340, alignment: .leading)
                        .padding()
                        // Popover content is hosted in a separate window and does not
                        // inherit the app-language locale injected at the root view
                        // (EasydictApp), so re-apply the surrounding locale here to keep
                        // the help text in the in-app language instead of the system one.
                        .environment(\.locale, locale)
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.locale) private var locale

    @State private var isShowingHelp = false

    @Default private var model: String
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
