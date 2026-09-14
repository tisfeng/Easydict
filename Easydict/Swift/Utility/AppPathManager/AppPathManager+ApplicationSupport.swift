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

    /// The root directory for all Easydict-managed logs.
    var logsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("logs", isDirectory: true)
    }

    /// The root directory for app, crash, and OCR diagnostic logs.
    var appLogDirectory: URL {
        logsDirectory.appendingPathComponent("app", isDirectory: true)
    }

    var ocrImageDirectory: URL {
        appLogDirectory.appendingPathComponent("Image", isDirectory: true)
    }

    var snipImageFileURL: URL {
        ocrImageDirectory.appendingPathComponent("snip_image.png", isDirectory: false)
    }

    var ocrCroppedImageFileURL: URL {
        ocrImageDirectory.appendingPathComponent("ocr_cropped_image.png", isDirectory: false)
    }

    var codexCLILogDirectory: URL {
        logsDirectory.appendingPathComponent("codex-cli", isDirectory: true)
    }

    var claudeCodeLogDirectory: URL {
        logsDirectory.appendingPathComponent("claude-code", isDirectory: true)
    }

    /// The root directory for app-managed disposable data.
    var cacheDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("cache", isDirectory: true)
    }

    /// The directory containing downloaded pronunciation audio.
    var audioCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("audio", isDirectory: true)
    }

    var mdictMetadataCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("mdict-metadata", isDirectory: true)
    }

    /// The previous MDict metadata cache location.
    var legacyMDictMetadataCacheDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("mdict-metadata-cache", isDirectory: true)
    }
}
