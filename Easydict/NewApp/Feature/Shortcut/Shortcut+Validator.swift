//
//  Shortcut+Validator.swift
//  Easydict
//
//  Created by Sharker on 2024/1/29.
//  Copyright © 2024 izual. All rights reserved.
//

import Carbon
import Foundation
import KeyHolder
import Magnet
import Sauce

extension Shortcut {
    static func validateShortcut(_ keyCombo: KeyCombo) -> Bool {
        validateShortcutConfictBySystem(keyCombo) ||
            validateShortcutConfictByMenuItem(keyCombo) ||
            validateShortcutConfictByCustom(keyCombo)
    }
}

// validate shortcut used by system
// ref: https://github.com/cocoabits/MASShortcut/blob/6f2603c6b6cc18f64a799e5d2c9d3bbc467c413a/Framework/Model/MASShortcutValidator.m#L94
extension Shortcut {
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
extension Shortcut {
    static func validateShortcutConfictByMenuItem(_ keyCombo: KeyCombo) -> Bool {
        if let item = menuItemUsedShortcut(keyCombo) {
            Shortcut.shared.confictMenuItem = item
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

// validate shortcut used by custom
// ref: https://support.apple.com/zh-cn/HT201236
extension Shortcut {
    static func validateShortcutConfictByCustom(_: KeyCombo) -> Bool {
        false
    }

    static func customUsedShortcut(_: KeyCombo) {}
}
