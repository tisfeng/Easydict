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
            CopilotModelSelection(modelKey: service.modelKey, effortKey: service.effortKey)
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

/// Owns loading and picker state locally so catalog updates do not invalidate the service list.
private struct CopilotModelSelection: View {
    // MARK: Lifecycle

    init(modelKey: Defaults.Key<String>, effortKey: Defaults.Key<String>) {
        _model = .init(modelKey)
        _effort = .init(effortKey)
    }

    // MARK: Internal

    var body: some View {
        LabeledContent("service.configuration.github_copilot.model.title") {
            HStack {
                Button {
                    search = ""
                    showingModels = true
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
        .task(id: refreshID) { await reload() }
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
    @State private var catalog: GitHubCopilotModelCatalog.Snapshot?
    @State private var isLoading = false
    @State private var failure: String?
    @State private var refreshID = UUID()
    @State private var activeLoad: UUID?
    @State private var search = ""
    @State private var showingModels = false

    @Default private var model: String
    @Default private var effort: String

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

    private var defaultModelTitle: String {
        guard let catalog, !catalog.defaultModelID.isEmpty else {
            return String(localized: "service.github_copilot.catalog.default_model")
        }
        let name = catalog.models.first { $0.id == catalog.defaultModelID }?.name ?? catalog.defaultModelID
        return String(format: String(localized: "service.github_copilot.catalog.default_model_value %@"), name)
    }

    private var selectionTitle: String {
        model.isEmpty ? defaultModelTitle : catalog?.models.first { $0.id == model }?.name ?? model
    }

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
            model = id
            if !efforts.contains(effort) { effort = "" }
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

    @MainActor
    private func reload() async {
        let identifier = UUID()
        activeLoad = identifier
        isLoading = true
        failure = nil
        defer { if activeLoad == identifier { isLoading = false } }
        do {
            let result = try await GitHubCopilotModelCatalog.load()
            try Task.checkCancellation()
            guard activeLoad == identifier else { return }
            catalog = result
            if !efforts.contains(effort) { effort = "" }
        } catch is CancellationError {
            // Switching services or leaving settings cancels the metadata subprocess.
        } catch {
            guard activeLoad == identifier else { return }
            failure = error.localizedDescription
        }
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
