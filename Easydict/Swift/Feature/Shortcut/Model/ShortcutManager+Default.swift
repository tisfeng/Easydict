//
//  ShortcutManager+Default.swift
//  Easydict
//
//  Created by Sharker on 2024/2/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Magnet

// MARK: - ShortcutManager + Defaults Settings

extension ShortcutManager {
    // Set defalut hotkeys for global and app
    func setDefaultShortcutKeys() {
        setDefaultGlobalShortcutKeys()
        setDefaultAppShortcutKeys()
    }

    private func setDefaultGlobalShortcutKeys() {
        Defaults[.inputShortcut] = KeyCombo(key: .a, cocoaModifiers: .option)
        Defaults[.snipShortcut] = KeyCombo(key: .s, cocoaModifiers: .option)
        Defaults[.selectionShortcut] = KeyCombo(key: .d, cocoaModifiers: .option)
        Defaults[.showMiniWindowShortcut] = KeyCombo(key: .f, cocoaModifiers: .option)
        Defaults[.silentScreenshotOCRShortcut] = KeyCombo(key: .s, cocoaModifiers: [.option, .shift])
    }

    private func setDefaultAppShortcutKeys() {
        Defaults[.clearInputShortcut] = KeyCombo(key: .k, cocoaModifiers: .command)
        Defaults[.clearAllShortcut] = KeyCombo(key: .k, cocoaModifiers: [.command, .shift])
        Defaults[.copyShortcut] = KeyCombo(key: .c, cocoaModifiers: [.command, .shift])
        Defaults[.copyFirstResultShortcut] = KeyCombo(key: .j, cocoaModifiers: [.command, .shift])
        Defaults[.focusShortcut] = KeyCombo(key: .i, cocoaModifiers: .command)
        Defaults[.playShortcut] = KeyCombo(key: .s, cocoaModifiers: .command)
        Defaults[.retryShortcut] = KeyCombo(key: .r, cocoaModifiers: .command)
        Defaults[.toggleShortcut] = KeyCombo(key: .t, cocoaModifiers: .command)
        Defaults[.pinShortcut] = KeyCombo(key: .p, cocoaModifiers: .command)
        Defaults[.hideShortcut] = KeyCombo(key: .y, cocoaModifiers: .command)
        Defaults[.increaseFontSize] = KeyCombo(key: .keypadPlus, cocoaModifiers: .command)
        Defaults[.decreaseFontSize] = KeyCombo(key: .keypadMinus, cocoaModifiers: .command)
        Defaults[.googleShortcut] = KeyCombo(key: .return, cocoaModifiers: .command)
        Defaults[.eudicShortcut] = KeyCombo(key: .return, cocoaModifiers: [.command, .shift])
        Defaults[.appleDictionaryShortcut] = KeyCombo(key: .d, cocoaModifiers: [.command, .shift])
    }
}

// MARK: - ShortcutManager + GlobalShortcut

extension ShortcutManager {
    /// Setup global shortcut actions
    func setupGlobalShortcutActions() {
        let globalActions: [ShortcutAction] = [
            .inputTranslate,
            .snipTranslate,
            .selectTranslate,
            .pasteboardTranslate,
            .showMiniWindow,
            .silentScreenshotOCR,
        ]

        for action in globalActions {
            if let key = action.defaultsKey {
                let keyCombo = Defaults[key]
                bindingShortcutAction(keyCombo: keyCombo, action: action)
            }
        }
    }

    /// Bind default shortcut action
    func bindingShortcutAction(keyCombo: KeyCombo?, action: ShortcutAction) {
        HotKeyCenter.shared.unregisterHotKey(with: action.rawValue)
        guard let keyCombo else {
            return
        }

        let hotKey = HotKey(
            identifier: action.rawValue,
            keyCombo: keyCombo
        ) { _ in
            Task { @MainActor in
                action.executeAction()
            }
        }

        hotKey.register()
    }
}
