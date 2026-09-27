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
            CopilotModelSelection(service: service, store: .shared)
                .id(service.uuid)
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

// MARK: - CopilotModelSelection

/// Observes shared metadata only in the model section, keeping service-list updates local.
private struct CopilotModelSelection: View {
    // MARK: Lifecycle

    init(service: GitHubCopilotService, store: GitHubCopilotModelStore) {
        self.service = service
        self.store = store
        _model = .init(service.modelKey)
        _effort = .init(service.effortKey)
    }

    // MARK: Internal

    var body: some View {
        LabeledContent("service.configuration.github_copilot.model.title") {
            HStack {
                Button {
                    search = ""
                    showingModels = true
                    refreshID = UUID()
                } label: {
                    HStack {
                        Text(selectionTitle)
                        Image(systemSymbol: .chevronUpChevronDown)
                    }
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingModels) {
                    modelPicker.environment(\.locale, locale)
                }
                Button {
                    refreshID = UUID()
                } label: {
                    Image(systemSymbol: .arrowClockwise)
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
                .help("service.github_copilot.catalog.refresh")
                .accessibilityLabel("service.github_copilot.catalog.refresh")
            }
        }
        .task(id: refreshID) { await store.refresh() }
        .onChange(of: store.revision) { _ in
            store.normalizeEffort(for: model, effortKey: service.effortKey)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { refreshID = UUID() }
        }
        if isLoading {
            HStack {
                ProgressView().controlSize(.small)
                Text("service.github_copilot.catalog.loading")
                    .foregroundStyle(.secondary)
            }
        }
        if let failure {
            HStack {
                Text(failure).font(.caption).foregroundStyle(.orange)
                Spacer()
                Button("retry") { refreshID = UUID() }
                    .disabled(isLoading)
            }
        }
        if let catalog, !model.isEmpty || !catalog.defaultModelID.isEmpty, catalog.model(for: model) == nil {
            Text("service.github_copilot.catalog.selection_unavailable")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        if !efforts.isEmpty {
            Picker("service.configuration.github_copilot.effort.title", selection: effortSelection) {
                Text(defaultEffortTitle).tag("")
                ForEach(efforts, id: \.self) { value in
                    Text(GitHubCopilotEffort.title(for: value)).tag(value)
                }
            }
        }
    }

    // MARK: Private

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @ObservedObject private var store: GitHubCopilotModelStore
    @State private var refreshID = UUID()
    @State private var search = ""
    @State private var showingModels = false

    private let service: GitHubCopilotService

    @Default private var model: String
    @Default private var effort: String

    private var catalog: GitHubCopilotModelCatalog.Snapshot? { store.snapshot }
    private var isLoading: Bool { store.isLoading }
    private var failure: String? { store.failure }

    private var efforts: [String] { catalog?.model(for: model)?.reasoningEfforts ?? [] }

    private var effortSelection: Binding<String> {
        Binding(get: { efforts.contains(effort) ? effort : "" }, set: { effort = $0 })
    }

    private var defaultEffortTitle: String {
        if let value = catalog?.model(for: model)?.defaultReasoningEffort, efforts.contains(value) {
            return String(
                format: String(localized: "service.github_copilot.effort.default_value %@"),
                GitHubCopilotEffort.title(for: value)
            )
        }
        return GitHubCopilotEffort.title(for: "")
    }

    private var defaultModelTitle: String { store.defaultModelTitle }

    private var selectionTitle: String { store.title(for: model) }

    private var matchingModels: [GitHubCopilotModel] {
        (catalog?.models ?? []).filter {
            $0.isAvailable && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)
                || $0.id.localizedCaseInsensitiveContains(search))
        }
    }

    private var modelPicker: some View {
        VStack(alignment: .leading) {
            TextField("service.github_copilot.catalog.search", text: $search)
                .textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    modelButton(id: "", title: defaultModelTitle)
                    Divider()
                    ForEach(matchingModels) { option in
                        modelButton(id: option.id, title: option.name)
                    }
                    if matchingModels.isEmpty {
                        Text(isLoading ? "service.github_copilot.catalog.loading"
                            : "service.github_copilot.catalog.no_models")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .frame(width: 320)
    }

    private func modelButton(id: String, title: String) -> some View {
        Button {
            service.selectModel(id)
            showingModels = false
        } label: {
            HStack {
                Text(verbatim: title)
                Spacer()
                if model == id { Image(systemSymbol: .checkmark) }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
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
