//
//  GitHubCopilotModelStore.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/27.
//

import Combine
import Defaults
import Foundation

/// Serves the saved catalog to all windows, with scheduled and manual CLI refreshes.
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

    /// Register once at launch; menu and translation paths never start a refresh.
    func startAutomaticRefresh() {
        guard automaticRefreshTimer == nil else { return }
        let timer = Timer(
            fire: Date(timeIntervalSinceNow: 5), interval: 24 * 60 * 60, repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshAutomaticallyIfEnabled()
            }
        }
        automaticRefreshTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    /// Stop scheduling and cancel any remaining catalog request when the app terminates.
    func stopAutomaticRefresh() {
        automaticRefreshTimer?.invalidate()
        automaticRefreshTimer = nil
        loadingTask?.cancel()
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
                try Task.checkCancellation()
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
    private var automaticRefreshTimer: Timer?

    private func refreshAutomaticallyIfEnabled() async {
        // A queued timer callback must not start work after the scheduler was stopped.
        guard automaticRefreshTimer != nil else { return }
        let windowTypes: [EZWindowType] = [.main, .mini, .fixed]
        let isEnabled = windowTypes.contains {
            LocalStorage.shared().enabledServiceTypeIDs($0).contains(ServiceType.gitHubCopilot.rawValue)
        }
        guard isEnabled else { return }
        await refresh()
    }
}
