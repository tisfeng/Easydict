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
    func setDefaultForAppShortcut() {
        Defaults[.clearInputShortcut] = KeyCombo(QWERTYKeyCode: 40, cocoaModifiers: .command)
        Defaults[.clearAllShortcut] = KeyCombo(QWERTYKeyCode: 40, cocoaModifiers: [.command, .shift])
        Defaults[.copyShortcut] = KeyCombo(QWERTYKeyCode: 8, cocoaModifiers: [.command, .shift])
        Defaults[.copyFirstResultShortcut] = KeyCombo(QWERTYKeyCode: 38, cocoaModifiers: [.command, .shift])
        Defaults[.focusShortcut] = KeyCombo(QWERTYKeyCode: 34, cocoaModifiers: .command)
        Defaults[.playShortcut] = KeyCombo(QWERTYKeyCode: 1, cocoaModifiers: .command)
        Defaults[.retryShortcut] = KeyCombo(QWERTYKeyCode: 15, cocoaModifiers: .command)
        Defaults[.toggleShortcut] = KeyCombo(QWERTYKeyCode: 17, cocoaModifiers: .command)
        Defaults[.pinShortcut] = KeyCombo(QWERTYKeyCode: 35, cocoaModifiers: .command)
        Defaults[.hideShortcut] = KeyCombo(QWERTYKeyCode: 16, cocoaModifiers: .command)
        Defaults[.increaseFontSize] = KeyCombo(QWERTYKeyCode: 24, cocoaModifiers: .command)
        Defaults[.decreaseFontSize] = KeyCombo(QWERTYKeyCode: 27, cocoaModifiers: .command)
        Defaults[.googleShortcut] = KeyCombo(QWERTYKeyCode: 36, cocoaModifiers: .command)
        Defaults[.eudicShortcut] = KeyCombo(QWERTYKeyCode: 36, cocoaModifiers: [.command, .shift])
        Defaults[.appleDictionaryShortcut] = KeyCombo(QWERTYKeyCode: 2, cocoaModifiers: [.command, .shift])
    }
}
