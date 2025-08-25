//
//  ShortcutAction.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/25.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import Magnet
import SFSafeSymbols

// MARK: - ShortcutAction

/// Enum representing different application actions that can be triggered by shortcuts
public enum ShortcutAction: String {
    // Global shortcut
    case inputTranslate = "EZInputShortcutKey"
    case snipTranslate = "EZSnipShortcutKey"
    case selectTranslate = "EZSelectionShortcutKey"
    case showMiniWindow = "EZShowMiniShortcutKey"
    case silentScreenshotOCR = "EZSilentScreenshotOCRShortcutKey"
    case pasteboardTranslate = "EZPasteboardTranslateShortcutKey"

    // OCR specific shortcuts
    case screenshotOCR = "EZScreenshotOCRShortcutKey"
    case pasteboardOCR = "EZPasteboardOCRShortcutKey"
    case showOCRWindow = "EZShowOCRWindowShortcutKey"

    // In App shortcut
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

extension ShortcutAction {
    /// Get configuration for the shortcut type
    var configuration: ActionConfiguration {
        Self.configurations[self]
            ?? ActionConfiguration(
                titleKey: "unknown",
                icon: .questionmark,
                action: {}
            )
    }

    func localizedStringKey() -> String {
        configuration.titleKey
    }

    var icon: SFSymbol {
        configuration.icon
    }

    @MainActor
    func executeAction() {
        configuration.action()
    }

    /// Get the Defaults.Key for this shortcut action
    var defaultsKey: Defaults.Key<KeyCombo?> {
        Self.defaultsKeyMappings[self] ?? .inputShortcut // fallback to a safe default
    }
}

// MARK: - ShortcutAction Configurations

extension ShortcutAction {
    /// Static configurations for all shortcut types
    fileprivate static let configurations: [ShortcutAction: ActionConfiguration] = {
        let windowManager = EZWindowManager.shared()

        return [
            // Global shortcuts
            .inputTranslate: ActionConfiguration(
                titleKey: "menu_input_translate",
                icon: .keyboard,
                action: { windowManager.inputTranslate() }
            ),
            .snipTranslate: ActionConfiguration(
                titleKey: "menu_screenshot_Translate",
                icon: .cameraViewfinder,
                action: { windowManager.snipTranslate() }
            ),
            .selectTranslate: ActionConfiguration(
                titleKey: "menu_selectWord_Translate",
                icon: .highlighter,
                action: { windowManager.selectTextTranslate() }
            ),
            .silentScreenshotOCR: ActionConfiguration(
                titleKey: "menu_silent_screenshot_OCR",
                icon: .cameraMeteringSpot,
                action: { windowManager.silentScreenshotOCR() }
            ),
            .pasteboardTranslate: ActionConfiguration(
                titleKey: "menu_pasteboard_translate",
                icon: .docOnClipboard,
                action: { windowManager.pasteboardTranslate() }
            ),
            .showMiniWindow: ActionConfiguration(
                titleKey: "menu_show_mini_window",
                icon: .dockRectangle,
                action: { windowManager.showMiniFloatingWindow() }
            ),

            // OCR specific shortcuts
            .screenshotOCR: ActionConfiguration(
                titleKey: "menu_screenshot_OCR",
                icon: .cameraMeteringMultispot,
                action: { windowManager.screenshotOCR() }
            ),
            .pasteboardOCR: ActionConfiguration(
                titleKey: "menu_pasteboard_OCR",
                icon: .listClipboard,
                action: { AppleOCREngine().pasteboardOCR() }
            ),
            .showOCRWindow: ActionConfiguration(
                titleKey: "menu_show_ocr_window",
                icon: .textAndCommandMacwindow,
                action: { OCRWindowManager.shared.showWindow() }
            ),

            // In App shortcuts
            .clearInput: ActionConfiguration(
                titleKey: "shortcut_clear_input",
                icon: .deleteBackward,
                action: { /* Add action if needed */ }
            ),
            .clearAll: ActionConfiguration(
                titleKey: "shortcut_clear_all",
                icon: .clearFill,
                action: { /* Add action if needed */ }
            ),
            .copy: ActionConfiguration(
                titleKey: "shortcut_copy",
                icon: .docOnDoc,
                action: { /* Add action if needed */ }
            ),
            .copyFirstResult: ActionConfiguration(
                titleKey: "shortcut_copy_first_translated_text",
                icon: .docOnClipboard,
                action: { /* Add action if needed */ }
            ),
            .focus: ActionConfiguration(
                titleKey: "shortcut_focus",
                icon: .cursorarrowRays,
                action: { /* Add action if needed */ }
            ),
            .play: ActionConfiguration(
                titleKey: "shortcut_play",
                icon: .playFill,
                action: { /* Add action if needed */ }
            ),
            .retry: ActionConfiguration(
                titleKey: "retry",
                icon: .arrowClockwise,
                action: { /* Add action if needed */ }
            ),
            .toggle: ActionConfiguration(
                titleKey: "toggle_languages",
                icon: .arrowLeftArrowRight,
                action: { /* Add action if needed */ }
            ),
            .pin: ActionConfiguration(
                titleKey: "pin",
                icon: .pin,
                action: { /* Add action if needed */ }
            ),
            .hide: ActionConfiguration(
                titleKey: "hide",
                icon: .eyeSlash,
                action: { /* Add action if needed */ }
            ),
            .increaseFontSize: ActionConfiguration(
                titleKey: "shortcut_increase_font",
                icon: .textformatAlt,
                action: { /* Add action if needed */ }
            ),
            .decreaseFontSize: ActionConfiguration(
                titleKey: "shortcut_decrease_font",
                icon: .textformatAlt,
                action: { /* Add action if needed */ }
            ),
            .google: ActionConfiguration(
                titleKey: "open_in_google",
                icon: .magnifyingglass,
                action: { /* Add action if needed */ }
            ),
            .eudic: ActionConfiguration(
                titleKey: "open_in_eudic",
                icon: .bookClosed,
                action: { /* Add action if needed */ }
            ),
            .appleDic: ActionConfiguration(
                titleKey: "open_in_apple_dictionary",
                icon: .book,
                action: { /* Add action if needed */ }
            ),
        ]
    }()

    /// Mapping from ShortcutAction to corresponding Defaults.Key
    fileprivate static let defaultsKeyMappings: [ShortcutAction: Defaults.Key<KeyCombo?>] = [
        .inputTranslate: .inputShortcut,
        .snipTranslate: .snipShortcut,
        .selectTranslate: .selectionShortcut,
        .silentScreenshotOCR: .screenshotOCRShortcut,
        .pasteboardTranslate: .pasteboardTranslateShortcut,
        .showMiniWindow: .showMiniWindowShortcut,
        .screenshotOCR: .screenshotOCRShortcut,
        .pasteboardOCR: .pasteboardOCRShortcut,
        .showOCRWindow: .showOCRWindowShortcut,
        .clearInput: .clearInputShortcut,
        .clearAll: .clearAllShortcut,
        .copy: .copyShortcut,
        .copyFirstResult: .copyFirstResultShortcut,
        .focus: .focusShortcut,
        .play: .playShortcut,
        .retry: .retryShortcut,
        .toggle: .toggleShortcut,
        .pin: .pinShortcut,
        .hide: .hideShortcut,
        .increaseFontSize: .increaseFontSize,
        .decreaseFontSize: .decreaseFontSize,
        .google: .googleShortcut,
        .eudic: .eudicShortcut,
        .appleDic: .appleDictionaryShortcut,
    ]
}

// MARK: - ActionConfiguration

/// Configuration for shortcut types including icon, title, and action
struct ActionConfiguration {
    // MARK: Lifecycle

    init(titleKey: String, icon: SFSymbol, action: @MainActor @escaping () -> ()) {
        self.titleKey = titleKey
        self.icon = icon
        self.action = action
    }

    // MARK: Internal

    let titleKey: String
    let icon: SFSymbol
    let action: @MainActor () -> ()
}
