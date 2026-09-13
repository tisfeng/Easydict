//
//  AppPathManager+ApplicationSupport.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
    /// The root directory for Easydict-managed Codex files.
    var codexManagedDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("codex-managed", isDirectory: true)
    }

    /// The directory containing downloaded Codex runtime components.
    var codexManagedComponentsDirectory: URL {
        codexManagedDirectory.appendingPathComponent("components", isDirectory: true)
    }

    /// The isolated `CODEX_HOME` used by the managed Codex runtime.
    var codexManagedStateDirectory: URL {
        codexManagedDirectory.appendingPathComponent("state", isDirectory: true)
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
