//
//  Shortcut+Default.swift
//  Easydict
//
//  Created by Sharker on 2024/2/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Magnet

extension Shortcut {
    // set defalut for app shortcut
    func setDefaultForShortcut() {
        setDefaultForGlobalShortcut()
        setDefaultForAppShortcut()
    }

    private func setDefaultForGlobalShortcut() {
        Defaults[.selectionShortcut] = KeyCombo(key: .d, cocoaModifiers: .option)
        Defaults[.snipShortcut] = KeyCombo(key: .s, cocoaModifiers: .option)
        Defaults[.inputShortcut] = KeyCombo(key: .a, cocoaModifiers: .option)
        Defaults[.screenshotOCRShortcut] = KeyCombo(key: .f, cocoaModifiers: [.option, .shift])
        Defaults[.showMiniWindowShortcut] = KeyCombo(key: .s, cocoaModifiers: .option)
    }

    private func setDefaultForAppShortcut() {
        setDefaultForGlobalShortcut()

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
