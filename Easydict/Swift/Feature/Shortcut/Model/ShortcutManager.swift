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
    // MARK: Internal

    @objc static let shared = ShortcutManager()

    var confictShortcutTitle = ""

    @objc
    func setupShortcut() {
        // Set default shortcuts for first launch
        if Defaults[.firstLaunch] {
            Defaults[.firstLaunch] = false
            Defaults[.toggleAppendModeShortcutMigrated] = true
            setDefaultShortcutKeys()
        } else {
            migrateShortcutsIfNeeded()
        }

        // Bind global shortcut actions
        setupGlobalShortcutActions()
    }

    // MARK: Private

    private func migrateShortcutsIfNeeded() {
        if !Defaults[.toggleAppendModeShortcutMigrated] {
            Defaults[.toggleAppendModeShortcutMigrated] = true
            if Defaults[.toggleAppendModeShortcut] == nil {
                let defaultKeyCombo = KeyCombo(key: .a, cocoaModifiers: [.command, .shift])
                if !ShortcutManager.validateShortcutConfictBySavedShortcut(
                    defaultKeyCombo,
                    excluding: .toggleAppendMode
                ) {
                    Defaults[.toggleAppendModeShortcut] = defaultKeyCombo
                }
            }
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
