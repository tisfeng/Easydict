//
//  Shortcut.swift
//  Easydict
//
//  Created by Sharker on 2024/1/20.
//  Copyright © 2024 izual. All rights reserved.

import Defaults
import Foundation
import KeyHolder
import Magnet

/// Shortcut Service
enum ShortcutType: String {
    case inputTranslate = "EZInputShortcutKey"
    case snipTranslate = "EZSnipShortcutKey"
    case selectTranslate = "EZSelectionShortcutKey"
    case silentScreenshotOcr = "EZScreenshotOCRShortcutKey"
}

class Shortcut: NSObject {
    static let shared = Shortcut()

    static func setupShortcut() {
        let shortcut = Shortcut.shared
        shortcut.restoreShortcut()
    }

    // Make sure the class has only one instance
    // Should not init or copy outside
    override private init() {}

    override func copy() -> Any {
        self // SingletonClass.shared
    }

    override func mutableCopy() -> Any {
        self // SingletonClass.shared
    }

    // Optional
    func reset() {
        // Reset all properties to default value
    }
}

// restore shortcut
extension Shortcut {
    func restoreShortcut() {
        if let inputTranslateKeyCombo = restoreInputTranslate() {
            bindingShortCut(keyCombo: inputTranslateKeyCombo, type: .inputTranslate)
        }
        if let snipShortcutKeyKeyCombo = restoreSnipShortcutKey() {
            bindingShortCut(keyCombo: snipShortcutKeyKeyCombo, type: .snipTranslate)
        }
        if let selectionShortcutKeyCombo = restoreSelectionShortcutKey() {
            bindingShortCut(keyCombo: selectionShortcutKeyCombo, type: .selectTranslate)
        }
        if let screenshotOCRShortcutKeyCombo = restoreScreenshotOCRShortcutKey() {
            bindingShortCut(keyCombo: screenshotOCRShortcutKeyCombo, type: .silentScreenshotOcr)
        }
    }

    private func restoreInputTranslate() -> KeyCombo? {
        let data = Defaults[.inputShortcutKey]
        guard let keyCombo = try? JSONDecoder().decode(KeyCombo.self, from: data) else { return nil }
        return keyCombo
    }

    private func restoreSnipShortcutKey() -> KeyCombo? {
        let data = Defaults[.snipShortcutKey]
        guard let keyCombo = try? JSONDecoder().decode(KeyCombo.self, from: data) else { return nil }
        return keyCombo
    }

    private func restoreSelectionShortcutKey() -> KeyCombo? {
        let data = Defaults[.selectionShortcutKey]
        guard let keyCombo = try? JSONDecoder().decode(KeyCombo.self, from: data) else { return nil }
        return keyCombo
    }

    private func restoreScreenshotOCRShortcutKey() -> KeyCombo? {
        let data = Defaults[.screenshotOCRShortcutKey]
        guard let keyCombo = try? JSONDecoder().decode(KeyCombo.self, from: data) else { return nil }
        return keyCombo
    }
}

// binding shortcut
extension Shortcut {
    func bindingShortCut(keyCombo: KeyCombo, type: ShortcutType) {
        var hotKey: HotKey
        switch type {
        case .inputTranslate:
            hotKey = HotKey(identifier: type.rawValue,
                            keyCombo: keyCombo,
                            target: Shortcut.shared,
                            action: #selector(Shortcut.inputTranslate))
        case .snipTranslate:
            hotKey = HotKey(identifier: type.rawValue,
                            keyCombo: keyCombo,
                            target: Shortcut.shared,
                            action: #selector(Shortcut.snipTranslate))
        case .selectTranslate:
            hotKey = HotKey(identifier: type.rawValue,
                            keyCombo: keyCombo,
                            target: Shortcut.shared,
                            action: #selector(Shortcut.selectTextTranslate))
        case .silentScreenshotOcr:
            hotKey = HotKey(identifier: type.rawValue,
                            keyCombo: keyCombo,
                            target: Shortcut.shared,
                            action: #selector(Shortcut.screenshotOCR))
        }
        hotKey.register()
    }
}

// shortcut binding func
extension Shortcut {
    @objc func selectTextTranslate() {
        EZWindowManager.shared().selectTextTranslate()
    }

    @objc func snipTranslate() {
        EZWindowManager.shared().snipTranslate()
    }

    @objc func inputTranslate() {
        EZWindowManager.shared().inputTranslate()
    }

    @objc func showMiniFloatingWindow() {
        EZWindowManager.shared().showMiniFloatingWindow()
    }

    @objc func screenshotOCR() {
        EZWindowManager.shared().screenshotOCR()
    }
}
