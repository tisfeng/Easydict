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

// MARK: - ShortcutType

/// Shortcut Service
public enum ShortcutType: String {
    // Global
    case inputTranslate = "EZInputShortcutKey"
    case snipTranslate = "EZSnipShortcutKey"
    case selectTranslate = "EZSelectionShortcutKey"
    case showMiniWindow = "EZShowMiniShortcutKey"
    case silentScreenshotOCR = "EZScreenshotOCRShortcutKey"
    case pasteboardTranslate = "EZPasteboardTranslateShortcutKey"

    // In App
    case clearInput = "EZClearInputShortcutKey"
    case clearAll = "EZClearAllShortcutKey"
    case copy = "EZCopyShortcutKey"
    case copyFirstResult = "EZCopyFirstResultShortcutKey"
    case focus = "EZFocusShortcutKey"
    case play = "EZPlayShortcutKey"
    case retry = "EZRetryShortcutKey"
    case toggle = "EZToggleShortcutKey"
    case pin = "EZPinShortcutKey"
    case hide = "EZHideShortcutKey"
    case increaseFontSize = "EZIncreaseFontSizeShortcutKey"
    case decreaseFontSize = "EZDecreaseFontSizeShortcutKey"
    case google = "EZGoogleShortcutKey"
    case eudic = "EZEudicShortcutKey"
    case appleDic = "EZAppleDicShortcutKey"
}

extension ShortcutType {
    func localizedStringKey() -> String {
        switch self {
        case .inputTranslate:
            "menu_input_translate"
        case .snipTranslate:
            "menu_screenshot_Translate"
        case .selectTranslate:
            "menu_selectWord_Translate"
        case .silentScreenshotOCR:
            "menu_silent_screenshot_OCR"
        case .pasteboardTranslate:
            "menu_pasteboard_translate" // Fix Localizable warning: NSLocalizedString(@"menu_pasteboard_translate", nil);
        case .showMiniWindow:
            "menu_show_mini_window"
        case .clearInput:
            "shortcut_clear_input"
        case .clearAll:
            "shortcut_clear_all"
        case .copy:
            "shortcut_copy"
        case .copyFirstResult:
            "shortcut_copy_first_translated_text"
        case .focus:
            "shortcut_focus"
        case .play:
            "shortcut_play"
        case .retry:
            "retry"
        case .toggle:
            "toggle_languages"
        case .pin:
            "pin"
        case .hide:
            "hide"
        case .increaseFontSize:
            "shortcut_increase_font"
        case .decreaseFontSize:
            "shortcut_decrease_font"
        case .google:
            "open_in_google"
        case .eudic:
            "open_in_eudic"
        case .appleDic:
            "open_in_apple_dictionary"
        }
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

// MARK: - Shortcut

class Shortcut: NSObject {
    // MARK: Lifecycle

    // Make sure the class has only one instance
    // Should not init or copy outside
    override private init() {}

    // MARK: Internal

    static let shared = Shortcut()

    var confictMenuItem: NSMenuItem?

    override func copy() -> Any {
        self // SingletonClass.shared
    }

    override func mutableCopy() -> Any {
        self // SingletonClass.shared
    }

    @objc
    static func setupShortcut() {
        let shortcut = Shortcut.shared
        shortcut.restoreShortcut()

        if Defaults[.firstLaunch] {
            Defaults[.firstLaunch] = false
            // set defalut for app shortcut
            shortcut.setDefaultForShortcut()
        } else {
            // do nothing
        }
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
        bindingShortcut(keyCombo: Defaults[.screenshotOCRShortcut], type: .silentScreenshotOCR)
        // showMiniWindow
        bindingShortcut(keyCombo: Defaults[.showMiniWindowShortcut], type: .showMiniWindow)
        // pasteboardTranslate
        bindingShortcut(keyCombo: Defaults[.pasteboardTranslateShortcut], type: .pasteboardTranslate)
    }
}

// binding shortcut
extension Shortcut {
    func bindingShortcut(keyCombo: KeyCombo?, type: ShortcutType) {
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

// MARK: - KeyboardShortcut

struct KeyboardShortcut: ViewModifier {
    // MARK: Lifecycle

    init(type: ShortcutType) {
        let key: Defaults.Key<KeyCombo?> =
            switch type {
            case .inputTranslate:
                .inputShortcut
            case .snipTranslate:
                .snipShortcut
            case .selectTranslate:
                .selectionShortcut
            case .silentScreenshotOCR:
                .screenshotOCRShortcut
            case .pasteboardTranslate:
                .pasteboardTranslateShortcut
            case .showMiniWindow:
                .showMiniWindowShortcut
            case .clearInput:
                .clearInputShortcut
            case .clearAll:
                .clearAllShortcut
            case .copy:
                .copyShortcut
            case .copyFirstResult:
                .copyFirstResultShortcut
            case .focus:
                .focusShortcut
            case .play:
                .playShortcut
            case .retry:
                .retryShortcut
            case .toggle:
                .toggleShortcut
            case .pin:
                .pinShortcut
            case .hide:
                .hideShortcut
            case .increaseFontSize:
                .increaseFontSize
            case .decreaseFontSize:
                .decreaseFontSize
            case .google:
                .googleShortcut
            case .eudic:
                .eudicShortcut
            case .appleDic:
                .appleDictionaryShortcut
            }

        _shortcut = .init(key)
    }

    // MARK: Internal

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

    // MARK: Private

    private func fetchShortcutKeyEquivalent(_ keyCombo: KeyCombo) -> KeyEquivalent {
        if keyCombo.doubledModifiers {
            KeyEquivalent(Character(keyCombo.keyEquivalentModifierMaskString))
        } else {
            KeyEquivalent(Character(keyCombo.keyEquivalent))
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
extension View {
    @ViewBuilder
    public func keyboardShortcut(_ type: ShortcutType) -> some View {
        modifier(KeyboardShortcut(type: type))
    }
}
