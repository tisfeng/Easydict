//
//  GitHubCopilotModelCache.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/27.
//

import Foundation

/// Persists only model metadata, never CLI credentials or conversation state.
enum GitHubCopilotModelCache {
    static func load() throws -> GitHubCopilotModelCatalog.Snapshot? {
        let url = AppPathManager.current.githubCopilotModelCatalogURL
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(GitHubCopilotModelCatalog.Snapshot.self, from: Data(contentsOf: url))
    }

    /// A failed refresh or write leaves the previous catalog intact.
    static func save(_ snapshot: GitHubCopilotModelCatalog.Snapshot) throws {
        let url = AppPathManager.current.githubCopilotModelCatalogURL
        let data = try JSONEncoder().encode(snapshot)
        try AppPathManager.current.ensureDirectoryExists(at: url.deletingLastPathComponent())
        try data.write(to: url, options: .atomic)
    }
}
