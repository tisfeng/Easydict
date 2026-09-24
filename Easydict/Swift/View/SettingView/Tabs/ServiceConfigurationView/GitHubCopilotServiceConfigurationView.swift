//
//  GitHubCopilotServiceConfigurationView.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Defaults
import SFSafeSymbols
import SwiftUI

// MARK: - GitHubCopilotServiceConfigurationView

/// Configuration view for the GitHub Copilot translation service.
///
/// Hides the API key, endpoint, temperature, and think-tag sections, which do not apply to a CLI
/// tool. Authentication happens in the `copilot` CLI itself, so there is no login flow here.
struct GitHubCopilotServiceConfigurationView: View {
    // MARK: Lifecycle

    init(service: GitHubCopilotService) {
        self.service = service
    }

    // MARK: Internal

    var body: some View {
        Section {
            CLIStatusRow()
        }

        Section {
            ModelInputRow(key: service.modelKey)
            StaticPickerCell(
                titleKey: "service.configuration.github_copilot.effort.title",
                key: service.effortKey,
                values: GitHubCopilotEffort.allCases
            )
        }
        #if AGENT_CLI_DEBUG
        Section {
            Button("service.github_copilot.debug_log.show_window") {
                GitHubCopilotDebugWindowController.shared.toggle()
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

    private let service: GitHubCopilotService
}

// MARK: - ModelInputRow

/// The model text field with an info button describing the accepted values.
///
/// The CLI resolves its model catalog from the signed-in account, so which models work depends on
/// that account's plan. A free-form field avoids pinning a list that would go stale, and clearing
/// the field falls back to the CLI's own default model.
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
                prompt: Text("service.configuration.github_copilot.model.placeholder")
            ) {
                EmptyView()
            }
            .multilineTextAlignment(.trailing)
        } label: {
            HStack(spacing: 4) {
                Text("service.configuration.github_copilot.model.title")
                Button {
                    isShowingHelp.toggle()
                } label: {
                    Image(systemSymbol: .infoCircle)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isShowingHelp, arrowEdge: .bottom) {
                    Text(
                        "service.configuration.github_copilot.model.help \(GitHubCopilotModel.knownModelIDsText)"
                    )
                    .font(.callout)
                    .multilineTextAlignment(.leading)
                    .frame(width: 340, alignment: .leading)
                    .padding()
                    // Popover content is hosted in a separate window and does not inherit the
                    // app-language locale, so re-apply the surrounding locale here.
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

/// A row that shows whether the `copilot` binary is detectable on this machine.
private struct CLIStatusRow: View {
    // MARK: Internal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("service.github_copilot.name")
                    .font(.body)
                if let path = detectedPath {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("service.github_copilot.risk_warning")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                } else {
                    Text("service.github_copilot.not_installed")
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
            let path = GitHubCopilotRunner.detectBinaryPath()
            await MainActor.run { detectedPath = path }
        }
    }
}
