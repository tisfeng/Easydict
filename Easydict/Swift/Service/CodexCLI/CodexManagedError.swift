//
//  CodexManagedError.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Foundation

// MARK: - CodexManagedError

/// Errors specific to the bundled runtime, separate from the external CLI's
/// compatibility behavior. Authentication output is never included in these
/// messages, since it can contain browser authorization URLs and credential hints.
enum CodexManagedError: Error, LocalizedError, Equatable {
    case componentInvalid
    case componentMissing
    case externalConfiguration
    case timeout
    case outputTooLarge
    case invalidResponse
    case authenticationFailed
    case keychainUnavailable
    case loginRequired
    case operationInProgress(CodexAccountOperation)
    case invalidModel

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .componentInvalid: String(localized: "service.codex_cli.managed.component_invalid")
        case .componentMissing: String(localized: "service.codex_cli.managed.component_missing")
        case .externalConfiguration: String(localized: "service.codex_cli.managed.external_configuration")
        case .timeout: String(localized: "service.codex_cli.managed.timeout")
        case .outputTooLarge: String(localized: "service.codex_cli.managed.output_too_large")
        case .invalidResponse: String(localized: "service.codex_cli.managed.invalid_response")
        case .authenticationFailed: String(localized: "service.codex_cli.managed.authentication_failed")
        case .keychainUnavailable: String(localized: "service.codex_cli.managed.keychain_unavailable")
        case .loginRequired: String(localized: "service.codex_cli.managed.login_required")
        case let .operationInProgress(operation): operation.message
        case .invalidModel: String(localized: "service.codex_cli.managed.invalid_model")
        }
    }
}

// MARK: - CodexAccountOperation

/// Identifies account changes that temporarily prevent a new managed translation.
/// Read-only status checks and manual connection tests do not change account identity.
enum CodexAccountOperation: CaseIterable, Equatable {
    case login, logout, cancelRefresh, resetSettings

    // MARK: Internal

    var message: String {
        switch self {
        case .login: String(localized: "service.codex_cli.managed.operation.login")
        case .logout: String(localized: "service.codex_cli.managed.operation.logout")
        case .cancelRefresh: String(localized: "service.codex_cli.managed.operation.cancel_refresh")
        case .resetSettings: String(localized: "service.codex_cli.managed.operation.reset_settings")
        }
    }
}
