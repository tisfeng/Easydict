//
//  ActionConfiguration.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/25.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import Magnet
import SFSafeSymbols

// MARK: - ActionConfiguration

/// Configuration for shortcut types including icon, title, action, and defaults key
struct ActionConfiguration {
    // MARK: Lifecycle

    init(
        titleKey: String,
        icon: SFSymbol,
        defaultsKey: Defaults.Key<KeyCombo?>? = nil,
        action: @MainActor @escaping () async -> ()
    ) {
        self.titleKey = titleKey
        self.icon = icon
        self.defaultsKey = defaultsKey
        self.action = {
            Task { @MainActor in
                await action()
            }
        }
    }

    // MARK: Internal

    let titleKey: String
    let icon: SFSymbol
    let defaultsKey: Defaults.Key<KeyCombo?>?
    let action: @MainActor () async -> ()
}
