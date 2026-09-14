//
//  AppPathManager+ApplicationSupport.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
    /// The root directory for Easydict-managed Codex files.
    var codexDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("codex", isDirectory: true)
    }

    /// The directory containing downloaded Codex runtime components.
    var codexComponentsDirectory: URL {
        codexDirectory.appendingPathComponent("components", isDirectory: true)
    }

    /// The isolated `CODEX_HOME` used by the managed Codex runtime.
    var codexStateDirectory: URL {
        codexDirectory.appendingPathComponent("state", isDirectory: true)
    }

    /// Older roots checked by `CodexDirectoryMigration`, newest first.
    var legacyCodexDirectories: [URL] {
        let bundleScopedDirectory = applicationSupportDirectory
            .appendingPathComponent("codex-managed", isDirectory: true)
        let sharedDirectory = applicationSupportDirectory
            .deletingLastPathComponent()
            .appendingPathComponent("Easydict", isDirectory: true)
            .appendingPathComponent("codex-managed", isDirectory: true)
        return [bundleScopedDirectory, sharedDirectory]
    }

    /// The root directory for service invocation logs.
    var serviceLogsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("logs", isDirectory: true)
    }

    var codexCLILogDirectory: URL {
        serviceLogsDirectory.appendingPathComponent("codex-cli", isDirectory: true)
    }

    var claudeCodeLogDirectory: URL {
        serviceLogsDirectory.appendingPathComponent("claude-code", isDirectory: true)
    }

    var mdictMetadataCacheDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("mdict-metadata-cache", isDirectory: true)
    }
}
