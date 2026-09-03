//
//  ConfigurationBackupModels.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - ConfigurationBackupItem

/// A single semantic configuration value stored inside the encrypted payload.
struct ConfigurationBackupItem: Codable {
    let descriptor: ConfigurationItemDescriptor
    let valueKind: ConfigurationValueKind
    let value: Data
}

// MARK: - ConfigurationBackupPayload

/// Decrypted v1 payload. Raw UserDefaults keys are deliberately absent.
struct ConfigurationBackupPayload: Codable {
    static let schemaVersion: UInt16 = 1

    let schemaVersion: UInt16
    let bundleIdentifier: String
    let applicationVersion: String
    let applicationBuild: String
    let createdAt: Date
    let items: [ConfigurationBackupItem]
}

// MARK: - ConfigurationBackupPreview

/// Non-sensitive summary shown before a restore is applied.
struct ConfigurationBackupPreview: Equatable {
    let settingCount: Int
    let credentialCount: Int
    let newCount: Int
    let overwriteCount: Int
    let skippedUnsafeEndpointCount: Int
}

// MARK: - PreparedConfigurationRestore

/// Validated restore operation. Credential values remain internal and are never exposed to UI.
struct PreparedConfigurationRestore {
    let preview: ConfigurationBackupPreview
    let createdAt: Date
    let resolvedItems: [ResolvedConfigurationBackupItem]
}

// MARK: - ResolvedConfigurationBackupItem

struct ResolvedConfigurationBackupItem {
    let entry: ConfigurationRegistryEntry
    let value: Any
}

// MARK: - ConfigurationBackupError

enum ConfigurationBackupError: Error, Equatable, LocalizedError {
    case passwordTooShort
    case passwordMismatch
    case fileTooLarge
    case invalidFormat
    case unsupportedVersion
    case unsupportedKDFParameters
    case authenticationFailed
    case invalidPayload
    case wrongApplication
    case duplicateItem
    case unsupportedDescriptor
    case invalidValue
    case writeFailed
    case rollbackFailed
    case fileAccessFailed

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .passwordTooShort:
            String(localized: "configuration.backup.error.password_too_short")
        case .passwordMismatch:
            String(localized: "configuration.backup.error.password_mismatch")
        case .fileTooLarge:
            String(localized: "configuration.backup.error.file_too_large")
        case .authenticationFailed:
            String(localized: "configuration.backup.error.authentication_failed")
        case .unsupportedVersion:
            String(localized: "configuration.backup.error.unsupported_version")
        case .wrongApplication:
            String(localized: "configuration.backup.error.wrong_application")
        case .rollbackFailed, .writeFailed:
            String(localized: "configuration.backup.error.restore_failed")
        case .fileAccessFailed:
            String(localized: "configuration.backup.error.file_access")
        default:
            String(localized: "configuration.backup.error.invalid_file")
        }
    }
}
