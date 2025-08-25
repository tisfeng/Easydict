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
public enum ShortcutAction: String, Identifiable {
    // Global shortcuts
    case inputTranslate
    case snipTranslate
    case selectTranslate
    case showMiniWindow
    case pasteboardTranslate
    case silentScreenshotOCR

    // OCR specific shortcuts
    case screenshotOCR
    case pasteboardOCR
    case showOCRWindow

    // In App shortcuts
    case clearInput
    case clearAll
    case copy
    case copyFirstResult
    case focus
    case play
    case retry
    case toggle
    case pin
    case hide
    case increaseFontSize
    case decreaseFontSize
    case google
    case eudic
    case appleDic

    // MARK: Public

    public var id: String { rawValue }
}

extension ShortcutAction {
    /// Get configuration for the shortcut type
    var configuration: ActionConfiguration {
        Self.configurations[self]
            ?? ActionConfiguration(
                titleKey: "unknown",
                icon: .questionmark,
                defaultsKey: nil,
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
    var defaultsKey: Defaults.Key<KeyCombo?>? {
        configuration.defaultsKey
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
                defaultsKey: .inputShortcut,
                action: { windowManager.inputTranslate() }
            ),
            .snipTranslate: ActionConfiguration(
                titleKey: "menu_screenshot_Translate",
                icon: .cameraViewfinder,
                defaultsKey: .snipShortcut,
                action: { windowManager.snipTranslate() }
            ),
            .selectTranslate: ActionConfiguration(
                titleKey: "menu_selectWord_Translate",
                icon: .highlighter,
                defaultsKey: .selectionShortcut,
                action: { windowManager.selectTextTranslate() }
            ),
            .silentScreenshotOCR: ActionConfiguration(
                titleKey: "menu_silent_screenshot_OCR",
                icon: .cameraMeteringSpot,
                defaultsKey: .screenshotOCRShortcut,
                action: { windowManager.silentScreenshotOCR() }
            ),
            .pasteboardTranslate: ActionConfiguration(
                titleKey: "menu_pasteboard_translate",
                icon: .docOnClipboard,
                defaultsKey: .pasteboardTranslateShortcut,
                action: { windowManager.pasteboardTranslate() }
            ),
            .showMiniWindow: ActionConfiguration(
                titleKey: "menu_show_mini_window",
                icon: .dockRectangle,
                defaultsKey: .showMiniWindowShortcut,
                action: { windowManager.showMiniFloatingWindow() }
            ),

            // OCR specific shortcuts
            .screenshotOCR: ActionConfiguration(
                titleKey: "menu_screenshot_OCR",
                icon: .cameraMeteringMultispot,
                defaultsKey: .screenshotOCRShortcut,
                action: { windowManager.screenshotOCR() }
            ),
            .pasteboardOCR: ActionConfiguration(
                titleKey: "menu_pasteboard_OCR",
                icon: .listClipboard,
                defaultsKey: .pasteboardOCRShortcut,
                action: { AppleOCREngine().pasteboardOCR() }
            ),
            .showOCRWindow: ActionConfiguration(
                titleKey: "menu_show_ocr_window",
                icon: .textAndCommandMacwindow,
                defaultsKey: .showOCRWindowShortcut,
                action: { OCRWindowManager.shared.showWindow() }
            ),

            // In App shortcuts
            .clearInput: ActionConfiguration(
                titleKey: "shortcut_clear_input",
                icon: .deleteBackward,
                defaultsKey: .clearInputShortcut,
                action: { windowManager.clearInput() }
            ),
            .clearAll: ActionConfiguration(
                titleKey: "shortcut_clear_all",
                icon: .clearFill,
                defaultsKey: .clearAllShortcut,
                action: { windowManager.clearAll() }
            ),
            .copy: ActionConfiguration(
                titleKey: "shortcut_copy",
                icon: .docOnDoc,
                defaultsKey: .copyShortcut,
                action: { windowManager.copyQueryText() }
            ),
            .copyFirstResult: ActionConfiguration(
                titleKey: "shortcut_copy_first_translated_text",
                icon: .docOnClipboard,
                defaultsKey: .copyFirstResultShortcut,
                action: { windowManager.copyFirstTranslatedText() }
            ),
            .focus: ActionConfiguration(
                titleKey: "shortcut_focus",
                icon: .cursorarrowRays,
                defaultsKey: .focusShortcut,
                action: { windowManager.focusInputTextView() }
            ),
            .play: ActionConfiguration(
                titleKey: "shortcut_play",
                icon: .playFill,
                defaultsKey: .playShortcut,
                action: { windowManager.playOrStopQueryTextAudio() }
            ),
            .retry: ActionConfiguration(
                titleKey: "retry",
                icon: .arrowClockwise,
                defaultsKey: .retryShortcut,
                action: { windowManager.rerty() }
            ),
            .toggle: ActionConfiguration(
                titleKey: "toggle_languages",
                icon: .arrowLeftArrowRight,
                defaultsKey: .toggleShortcut,
                action: { windowManager.toggleTranslationLanguages() }
            ),
            .pin: ActionConfiguration(
                titleKey: "pin",
                icon: .pin,
                defaultsKey: .pinShortcut,
                action: { windowManager.pin() }
            ),
            .hide: ActionConfiguration(
                titleKey: "hide",
                icon: .eyeSlash,
                defaultsKey: .hideShortcut,
                action: { windowManager.closeWindowOrExitSreenshot() }
            ),
            .increaseFontSize: ActionConfiguration(
                titleKey: "shortcut_increase_font",
                icon: .textformatAlt,
                defaultsKey: .increaseFontSize,
                action: {
                    if Configuration.shared.fontSizeIndex < Configuration.shared.fontSizes.count - 1 {
                        Configuration.shared.fontSizeIndex += 1
                    }
                }
            ),
            .decreaseFontSize: ActionConfiguration(
                titleKey: "shortcut_decrease_font",
                icon: .textformatAlt,
                defaultsKey: .decreaseFontSize,
                action: {
                    if Configuration.shared.fontSizeIndex > 0 {
                        Configuration.shared.fontSizeIndex -= 1
                    }
                }
            ),
            .google: ActionConfiguration(
                titleKey: "open_in_google",
                icon: .magnifyingglass,
                defaultsKey: .googleShortcut,
                action: {
                    let window = windowManager.floatingWindow
                    window?.titleBar.googleButton.openLink()
                }
            ),
            .eudic: ActionConfiguration(
                titleKey: "open_in_eudic",
                icon: .bookClosed,
                defaultsKey: .eudicShortcut,
                action: {
                    let window = windowManager.floatingWindow
                    window?.titleBar.eudicButton.openLink()
                }
            ),
            .appleDic: ActionConfiguration(
                titleKey: "open_in_apple_dictionary",
                icon: .book,
                defaultsKey: .appleDictionaryShortcut,
                action: {
                    let window = windowManager.floatingWindow
                    window?.titleBar.appleDictionaryButton.openLink()
                }
            ),
        ]
    }()
}
