//
//  GitHubCopilotModelCatalog.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/27.
//

import Foundation

/// Queries the installed CLI without creating a conversation or making an inference request.
/// Called by scheduled or manual refreshes; selection and translation use the saved catalog.
enum GitHubCopilotModelCatalog {
    struct Snapshot: Codable, Sendable {
        let models: [GitHubCopilotModel]
        let defaultModelID: String
        let updatedAt: Date

        func model(for selection: String) -> GitHubCopilotModel? {
            let identifier = selection.isEmpty ? defaultModelID : selection
            return models.first { $0.id == identifier && $0.isAvailable }
        }
    }

    static func load() async throws -> Snapshot {
        let task = Task.detached(priority: .userInitiated) {
            guard let binary = GitHubCopilotRunner.detectBinaryPath() else {
                throw GitHubCopilotError.notInstalled
            }
            let environment = GitHubCopilotEnvironment.resolve()
            let sandbox = try GitHubCopilotRunner.makeSandboxDirectory()
            defer { GitHubCopilotRunner.removeSandbox(sandbox) }
            try Task.checkCancellation()
            try GitHubCopilotEnvironment.prepareAuthentication(in: sandbox.homeDirectory, environment: environment)
            let client = GitHubCopilotCatalogClient()
            let models = try await client.models(
                binary: binary, workingDirectory: sandbox.workingDirectory,
                logDirectory: sandbox.logDirectory,
                environment: GitHubCopilotRunner.buildProcessEnvironment(
                    homeDirectoryPath: sandbox.homeDirectory.path, inheritedEnvironment: environment
                )
            )
            let defaultModelID = try GitHubCopilotEnvironment.defaultModel(environment: environment)
            return Snapshot(models: models, defaultModelID: defaultModelID, updatedAt: Date())
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
