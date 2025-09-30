//
//  ShortcutManager.swift
//  Easydict
//
//  Created by Sharker on 2024/1/20.
//  Copyright © 2024 izual. All rights reserved.

import Defaults
import Foundation
import Magnet

// MARK: - ShortcutManager

class ShortcutManager: NSObject {
    @objc static let shared = ShortcutManager()

    var confictMenuItem: NSMenuItem?

    @objc
    func setupShortcut() {
        setupGlobalShortcutActions()

        // Set default shortcut for first launch
        if Defaults[.firstLaunch] {
            Defaults[.firstLaunch] = false
            setDefaultShortcutKeys()
        }
    }
}

// MARK: - Update Menu action

extension ShortcutManager {
    /// Update shortcut menu
    func updateMenu(_ action: ShortcutAction) {
        let shortcutTitle = String(
            localized: LocalizedStringResource(stringLiteral: action.localizedStringKey())
        )
        let menuTitle = String(localized: LocalizedStringResource(stringLiteral: "shortcut"))
        let shortcutMenu = NSApp.mainMenu?.items.first(where: { $0.title == menuTitle })
        let clearInput = shortcutMenu?.submenu?.items.first(where: { $0.title == shortcutTitle })
        clearInput?.keyEquivalent = ""
    }
}
