//
//  AppPathManager+Logs.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
    /// The root directory for all Easydict-managed logs.
    var logsDirectory: URL {
        appSupportDirectory.appendingPathComponent("logs", isDirectory: true)
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

    /// The previous CocoaLumberjack-compatible log root.
    var legacyAppLogDirectory: URL {
        cachesDirectory.appendingPathComponent("MMLogs", isDirectory: true)
    }
}
