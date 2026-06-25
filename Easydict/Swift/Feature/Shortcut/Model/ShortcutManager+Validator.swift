//
//  ShortcutManager+Validator.swift
//  Easydict
//
//  Created by Sharker on 2024/1/29.
//  Copyright © 2024 izual. All rights reserved.
//

import Carbon
import Defaults
import Foundation
import KeyHolder
import Magnet
import Sauce

extension ShortcutManager {
    static func validateShortcut(_ keyCombo: KeyCombo, excluding action: ShortcutAction? = nil) -> Bool {
        ShortcutManager.shared.confictShortcutTitle = ""
        return validateShortcutConfictBySystem(keyCombo) ||
            validateShortcutConfictByMenuItem(keyCombo) ||
            validateShortcutConfictBySavedShortcut(keyCombo, excluding: action) ||
            validateShortcutConfictByCustom(keyCombo)
    }
}

// validate shortcut used by system
// ref: https://github.com/cocoabits/MASShortcut/blob/6f2603c6b6cc18f64a799e5d2c9d3bbc467c413a/Framework/Model/MASShortcutValidator.m#L94
extension ShortcutManager {
    static func validateShortcutConfictBySystem(_ keyCombo: KeyCombo) -> Bool {
        systemUsedShortcut().contains(keyCombo)
    }

    static func systemUsedShortcut() -> [KeyCombo] {
        var shortcutsUnmanaged: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&shortcutsUnmanaged) == noErr,
              let shortcuts = shortcutsUnmanaged?.takeRetainedValue() as? [[String: Any]]
        else {
            assertionFailure("Could not get system keyboard shortcuts")
            return []
        }
        return shortcuts.compactMap {
            guard ($0[kHISymbolicHotKeyEnabled] as? Bool) == true,
                  let carbonKeyCode = $0[kHISymbolicHotKeyCode] as? Int,
                  let carbonModifiers = $0[kHISymbolicHotKeyModifiers] as? Int
            else {
                return nil
            }
            guard let key = Sauce.shared.key(for: Int(carbonKeyCode)) else { return nil }
            guard let keyCombo = KeyCombo(key: key, carbonModifiers: carbonModifiers) else { return nil }
            return keyCombo
        }
    }
}

// validate shortcut used by menuItem
extension ShortcutManager {
    static func validateShortcutConfictByMenuItem(_ keyCombo: KeyCombo) -> Bool {
        if let item = menuItemUsedShortcut(keyCombo) {
            ShortcutManager.shared.confictShortcutTitle = item.title
            return true
        } else {
            return false
        }
    }

    static func menuItemUsedShortcut(_ keyCombo: KeyCombo) -> NSMenuItem? {
        guard let mainMenu = NSApp.mainMenu else {
            return nil
        }
        return menuItemWithMatchingShortcut(in: mainMenu, keyCombo: keyCombo)
    }

    static func menuItemWithMatchingShortcut(in menu: NSMenu, keyCombo: KeyCombo) -> NSMenuItem? {
        for item in menu.items {
            let keyEquivalent = item.keyEquivalent
            let keyEquivalentModifierMask = item.keyEquivalentModifierMask
            if keyCombo.keyEquivalent == keyEquivalent,
               keyCombo.keyEquivalentModifierMask == keyEquivalentModifierMask,
               keyCombo.keyEquivalent != "" {
                return item
            }
            if let submenu = item.submenu,
               let menuItem = menuItemWithMatchingShortcut(in: submenu, keyCombo: keyCombo) {
                return menuItem
            }
        }
        return nil
    }
}

// validate shortcut used by saved shortcut defaults
extension ShortcutManager {
    static func validateShortcutConfictBySavedShortcut(
        _ keyCombo: KeyCombo, excluding action: ShortcutAction? = nil
    )
        -> Bool {
        guard let matchedAction = ShortcutAction.allCases.first(where: { savedAction in
            guard savedAction != action,
                  let defaultsKey = savedAction.defaultsKey,
                  let savedKeyCombo = Defaults[defaultsKey]
            else {
                return false
            }
            return savedKeyCombo == keyCombo
        }) else {
            return false
        }

        ShortcutManager.shared.confictShortcutTitle = String(
            localized: LocalizedStringResource(stringLiteral: matchedAction.localizedStringKey())
        )
        return true
    }
}

// validate shortcut used by custom
// ref: https://support.apple.com/zh-cn/HT201236
extension ShortcutManager {
    static func validateShortcutConfictByCustom(_: KeyCombo) -> Bool {
        false
    }

    static func customUsedShortcut(_: KeyCombo) {}
}
