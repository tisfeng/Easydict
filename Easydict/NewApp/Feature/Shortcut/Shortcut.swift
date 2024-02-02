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
import SwiftUI

/// Shortcut Service
public enum ShortcutType: String {
    case inputTranslate = "EZInputShortcutKey"
    case snipTranslate = "EZSnipShortcutKey"
    case selectTranslate = "EZSelectionShortcutKey"
    case silentScreenshotOcr = "EZScreenshotOCRShortcutKey"
    case showMiniWindow = "EZShowMiniShortcutKey"
}

// Confict Message
public struct ShortcutConfictAlertMessage: Identifiable {
    public var id: String { message }
    var title: String
    var message: String
}

class Shortcut: NSObject {
    var confictMenuItem: NSMenuItem?

    static let shared = Shortcut()

    @objc static func setupShortcut() {
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
        // inputTranslate
        bindingShortcut(keyCombo: Defaults[.inputShortcut], type: .inputTranslate)
        // snipTranslate
        bindingShortcut(keyCombo: Defaults[.snipShortcut], type: .snipTranslate)
        // selectTranslate
        bindingShortcut(keyCombo: Defaults[.selectionShortcut], type: .selectTranslate)
        // silentScreenshotOcr
        bindingShortcut(keyCombo: Defaults[.screenshotOCRShortcut], type: .silentScreenshotOcr)
        // showMiniWindow
        bindingShortcut(keyCombo: Defaults[.showMiniWindowShortcut], type: .showMiniWindow)
    }
}

// binding shortcut
extension Shortcut {
    func bindingShortcut(keyCombo: KeyCombo?, type: ShortcutType) {
        guard let keyCombo else {
            HotKeyCenter.shared.unregisterHotKey(with: type.rawValue)
            return
        }
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
        case .showMiniWindow:
            hotKey = HotKey(identifier: type.rawValue,
                            keyCombo: keyCombo,
                            target: Shortcut.shared,
                            action: #selector(Shortcut.showMiniFloatingWindow))
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

// fetch shortcut KeyCombo
extension Shortcut {
    public func shortcutKeyCombo(_ type: ShortcutType) -> KeyCombo? {
        switch type {
        case .inputTranslate:
            guard let keyCombo = Defaults[.inputShortcut] else { return nil }
            return keyCombo
        case .snipTranslate:
            guard let keyCombo = Defaults[.snipShortcut] else { return nil }
            return keyCombo
        case .selectTranslate:
            guard let keyCombo = Defaults[.selectionShortcut] else { return nil }
            return keyCombo
        case .silentScreenshotOcr:
            guard let keyCombo = Defaults[.screenshotOCRShortcut] else { return nil }
            return keyCombo
        case .showMiniWindow:
            guard let keyCombo = Defaults[.showMiniWindowShortcut] else { return nil }
            return keyCombo
        }
    }
}

struct KeyboardShortcut: ViewModifier {
    init(type: ShortcutType) {
        let key: Defaults.Key<KeyCombo?> = switch type {
        case .inputTranslate:
            .inputShortcut
        case .snipTranslate:
            .snipShortcut
        case .selectTranslate:
            .selectionShortcut
        case .silentScreenshotOcr:
            .screenshotOCRShortcut
        case .showMiniWindow:
            .showMiniWindowShortcut
        }

        _shortcut = .init(key)
    }

    @Default var shortcut: KeyCombo?

    func body(content: Content) -> some View {
        if let shortcut {
            content
                .keyboardShortcut(
                    fetchShortcutKeyEquivalent(shortcut),
                    modifiers: fetchShortcutKeyEventModifiers(shortcut)
                )
        } else {
            content
        }
    }

    private func fetchShortcutKeyEquivalent(_ keyCombo: KeyCombo) -> KeyEquivalent {
        if keyCombo.doubledModifiers {
            return KeyEquivalent(Character(keyCombo.keyEquivalentModifierMaskString))
        } else {
            return KeyEquivalent(Character(keyCombo.keyEquivalent))
        }
    }

    private func fetchShortcutKeyEventModifiers(_ keyCombo: KeyCombo) -> EventModifiers {
        var modifiers: EventModifiers = []

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.command) {
            modifiers.update(with: EventModifiers.command)
        }

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.control) {
            modifiers.update(with: EventModifiers.control)
        }

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.option) {
            modifiers.update(with: EventModifiers.option)
        }

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.shift) {
            modifiers.update(with: EventModifiers.shift)
        }

        return modifiers
    }
}

/// can't using keyEquivalent and EventModifiers in SwiftUI MenuItemView direct, because item
/// keyboardShortcut not support double modifier key but can use ⌥ as character
public extension View {
    @ViewBuilder
    func keyboardShortcut(_ type: ShortcutType) -> some View {
        modifier(KeyboardShortcut(type: type))
    }
}
