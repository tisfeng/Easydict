//
//  CodexAccessMode.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Defaults
import SwiftUI

// MARK: - CodexAccessMode

/// Selects the bundled ChatGPT environment or the user's existing CLI installation.
/// The persisted mode belongs to a service ID, while the managed account is shared
/// across all windows. Neither mode changes the other mode's model or credentials.
enum CodexAccessMode: String, CaseIterable, Defaults.Serializable {
    case managed
    case localCLI

    // MARK: Internal

    var enableMessage: LocalizedStringKey {
        switch self {
        case .managed: "service.codex_cli.managed.enable_message"
        case .localCLI: "service.codex_cli.enable_risk_alert.message"
        }
    }

    static func key(uuid: String) -> Defaults.Key<Self> {
        serivceConfigurationKey(.codexAccessMode, serviceType: .codexCLI, id: uuid, defaultValue: .managed)
    }
}

// MARK: EnumLocalizedStringConvertible

extension CodexAccessMode: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .managed: "service.codex_cli.mode.managed"
        case .localCLI: "service.codex_cli.mode.local"
        }
    }
}
