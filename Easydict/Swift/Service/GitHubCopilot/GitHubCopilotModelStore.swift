//
//  GitHubCopilotModelStore.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/27.
//

import Combine
import Defaults
import Foundation

/// Serves the saved catalog to all windows. Only settings explicitly refreshes it through the CLI.
@MainActor
final class GitHubCopilotModelStore: ObservableObject {
    // MARK: Lifecycle

    private init() {
        do {
            self.snapshot = try GitHubCopilotModelCache.load()
        } catch {
            self.failure = error.localizedDescription
        }
    }

    // MARK: Internal

    static let shared = GitHubCopilotModelStore()

    @Published private(set) var snapshot: GitHubCopilotModelCatalog.Snapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var failure: String?
    @Published private(set) var revision = 0

    var selectableModels: [String] {
        [""] + (snapshot?.models.filter(\.isAvailable).map(\.id) ?? [])
    }

    var defaultModelTitle: String {
        guard let identifier = snapshot?.defaultModelID, !identifier.isEmpty else {
            return String(localized: "service.github_copilot.catalog.default_model")
        }
        return String(
            format: String(localized: "service.github_copilot.catalog.default_model_value %@"),
            title(for: identifier)
        )
    }

    func title(for identifier: String) -> String {
        if identifier.isEmpty { return defaultModelTitle }
        return snapshot?.models.first { $0.id == identifier }?.name ?? identifier
    }

    /// A closing consumer does not cancel the bounded request needed by other consumers.
    func refresh() async {
        if let loadingTask {
            await loadingTask.value
            return
        }
        isLoading = true
        failure = nil
        let task = Task {
            do {
                let refreshed = try await GitHubCopilotModelCatalog.load()
                try GitHubCopilotModelCache.save(refreshed)
                snapshot = refreshed
                revision += 1
                NotificationCenter.default.post(name: .githubCopilotModelsDidChange, object: nil)
            } catch {
                failure = error.localizedDescription
            }
            isLoading = false
            loadingTask = nil
        }
        loadingTask = task
        await task.value
    }

    /// Normalize reasoning before publishing the model change that triggers translation.
    func selectModel(_ identifier: String, modelKey: Defaults.Key<String>, effortKey: Defaults.Key<String>) {
        normalizeEffort(for: identifier, effortKey: effortKey)
        if Defaults[modelKey] != identifier { Defaults[modelKey] = identifier }
    }

    func normalizeEffort(for identifier: String, effortKey: Defaults.Key<String>) {
        let effort = Defaults[effortKey]
        if !effort.isEmpty, snapshot?.model(for: identifier)?.reasoningEfforts.contains(effort) != true {
            Defaults[effortKey] = ""
        }
    }

    // MARK: Private

    private var loadingTask: Task<(), Never>?
}
