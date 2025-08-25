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
    // MARK: Lifecycle

    // Make sure the class has only one instance
    // Should not init or copy outside
    override private init() {}

    // MARK: Internal

    @objc static let shared = ShortcutManager()

    var confictMenuItem: NSMenuItem?

    override func copy() -> Any {
        self // SingletonClass.shared
    }

    override func mutableCopy() -> Any {
        self // SingletonClass.shared
    }

    @objc
    func setupShortcut() {
        restoreShortcut()

        // Set default shortcut for first launch
        if Defaults[.firstLaunch] {
            Defaults[.firstLaunch] = false
            setDefaultShortcuts()
        }
    }
}

extension ShortcutManager {
    /// Set default action for shortcut
    func restoreShortcut() {
        let globalActions: [ShortcutAction] = [
            .inputTranslate,
            .snipTranslate,
            .selectTranslate,
            .silentScreenshotOCR,
            .showMiniWindow,
            .pasteboardTranslate,
        ]

        for action in globalActions {
            let keyCombo = Defaults[action.defaultsKey]
            bindingShortcut(keyCombo: keyCombo, type: action)
        }
    }
}

extension ShortcutManager {
    /// Bind default shortcut
    func bindingShortcut(keyCombo: KeyCombo?, type: ShortcutAction) {
        HotKeyCenter.shared.unregisterHotKey(with: type.rawValue)
        guard let keyCombo else {
            return
        }
        var hotKey: HotKey?

        let windowManager = EZWindowManager.shared()

        switch type {
        case .inputTranslate:
            hotKey = HotKey(
                identifier: type.rawValue,
                keyCombo: keyCombo,
                target: windowManager,
                action: #selector(windowManager.inputTranslate)
            )
        case .snipTranslate:
            hotKey = HotKey(
                identifier: type.rawValue,
                keyCombo: keyCombo,
                target: windowManager,
                action: #selector(windowManager.snipTranslate)
            )
        case .selectTranslate:
            hotKey = HotKey(
                identifier: type.rawValue,
                keyCombo: keyCombo,
                target: windowManager,
                action: #selector(windowManager.selectTextTranslate)
            )
        case .silentScreenshotOCR:
            hotKey = HotKey(
                identifier: type.rawValue,
                keyCombo: keyCombo,
                target: windowManager,
                action: #selector(windowManager.silentScreenshotOCR)
            )
        case .showMiniWindow:
            hotKey = HotKey(
                identifier: type.rawValue,
                keyCombo: keyCombo,
                target: windowManager,
                action: #selector(windowManager.showMiniFloatingWindow)
            )
        case .pasteboardTranslate:
            hotKey = HotKey(
                identifier: type.rawValue,
                keyCombo: keyCombo,
                target: windowManager,
                action: #selector(windowManager.pasteboardTranslate)
            )
        default: ()
        }

        hotKey?.register()
    }
}

// MARK: - ShortcutConfictAlertMessage

// Confict Message
public struct ShortcutConfictAlertMessage: Identifiable {
    // MARK: Public

    public var id: String { message }

    // MARK: Internal

    var title: String
    var message: String
}
