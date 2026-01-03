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
public enum ShortcutAction: String, Identifiable, CaseIterable {
    // Global shortcuts
    case inputTranslate
    case snipTranslate
    case selectTranslate
    case showMiniWindow
    case pasteboardTranslate
    case polishAndReplace
    case translateAndReplace
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
    /// All global shortcut actions (system-wide hotkeys)
    static let globalActions: [ShortcutAction] = [
        .inputTranslate,
        .snipTranslate,
        .selectTranslate,
        .showMiniWindow,
        .pasteboardTranslate,
        .polishAndReplace,
        .translateAndReplace,
        .silentScreenshotOCR,
        .screenshotOCR,
        .pasteboardOCR,
        .showOCRWindow,
    ]

    /// All app-specific shortcut actions (only active when app is focused)
    static var appActions: [ShortcutAction] {
        allCases.filter { !globalActions.contains($0) }
    }

    /// Whether this action is a global shortcut (system-wide hotkey)
    var isGlobal: Bool {
        Self.globalActions.contains(self)
    }

    /// Get configuration for the shortcut type
    var configuration: ActionConfiguration {
        Self.configurations[self]
            ?? .init(
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
        Task {
            await configuration.action()
        }
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
            .inputTranslate: .init(
                titleKey: "menu_input_translate",
                icon: .keyboard,
                defaultsKey: .inputShortcut,
                action: { windowManager.inputTranslate() }
            ),
            .snipTranslate: .init(
                titleKey: "menu_screenshot_Translate",
                icon: .cameraViewfinder,
                defaultsKey: .snipShortcut,
                action: { windowManager.snipTranslate() }
            ),
            .selectTranslate: .init(
                titleKey: "menu_selectWord_Translate",
                icon: .highlighter,
                defaultsKey: .selectionShortcut,
                action: { windowManager.selectTextTranslate() }
            ),
            .silentScreenshotOCR: .init(
                titleKey: "menu_silent_screenshot_OCR",
                icon: .cameraMeteringSpot,
                defaultsKey: .silentScreenshotOCRShortcut,
                action: { windowManager.silentScreenshotOCR() }
            ),
            .pasteboardTranslate: .init(
                titleKey: "menu_pasteboard_translate",
                icon: .docOnClipboard,
                defaultsKey: .pasteboardTranslateShortcut,
                action: { windowManager.pasteboardTranslate(.fixed) }
            ),
            .polishAndReplace: .init(
                titleKey: "menu_polish_and_replace",
                icon: .wandAndStars,
                defaultsKey: .polishAndReplaceShortcut,
                action: { await ActionManager.shared.polishAndReplace() }
            ),
            .translateAndReplace: .init(
                titleKey: "menu_translate_and_replace",
                icon: .arrowLeftArrowRightSquare,
                defaultsKey: .translateAndReplaceShortcut,
                action: { await ActionManager.shared.translateAndReplace() }
            ),
            .showMiniWindow: .init(
                titleKey: "menu_show_mini_window",
                icon: .dockRectangle,
                defaultsKey: .showMiniWindowShortcut,
                action: { windowManager.showMiniFloatingWindow() }
            ),

            // OCR specific shortcuts
            .screenshotOCR: .init(
                titleKey: "menu_screenshot_OCR",
                icon: .cameraMeteringMultispot,
                defaultsKey: .screenshotOCRShortcut,
                action: { windowManager.screenshotOCR() }
            ),
            .pasteboardOCR: .init(
                titleKey: "menu_pasteboard_OCR",
                icon: .listClipboard,
                defaultsKey: .pasteboardOCRShortcut,
                action: { AppleOCREngine().pasteboardOCR() }
            ),
            .showOCRWindow: .init(
                titleKey: "menu_show_ocr_window",
                icon: .textAndCommandMacwindow,
                defaultsKey: .showOCRWindowShortcut,
                action: { OCRWindowManager.shared.showWindow() }
            ),

            // In App shortcuts
            .clearInput: .init(
                titleKey: "shortcut_clear_input",
                icon: .deleteBackward,
                defaultsKey: .clearInputShortcut,
                action: { windowManager.clearInput() }
            ),
            .clearAll: .init(
                titleKey: "shortcut_clear_all",
                icon: .clearFill,
                defaultsKey: .clearAllShortcut,
                action: { windowManager.clearAll() }
            ),
            .copy: .init(
                titleKey: "shortcut_copy",
                icon: .docOnDoc,
                defaultsKey: .copyShortcut,
                action: { windowManager.copyQueryText() }
            ),
            .copyFirstResult: .init(
                titleKey: "shortcut_copy_first_translated_text",
                icon: .docOnClipboard,
                defaultsKey: .copyFirstResultShortcut,
                action: { windowManager.copyFirstTranslatedText() }
            ),
            .focus: .init(
                titleKey: "shortcut_focus",
                icon: .cursorarrowRays,
                defaultsKey: .focusShortcut,
                action: { windowManager.focusInputTextView() }
            ),
            .play: .init(
                titleKey: "shortcut_play",
                icon: .playFill,
                defaultsKey: .playShortcut,
                action: { windowManager.playOrStopQueryTextAudio() }
            ),
            .retry: .init(
                titleKey: "retry",
                icon: .arrowClockwise,
                defaultsKey: .retryShortcut,
                action: { windowManager.rerty() }
            ),
            .toggle: .init(
                titleKey: "toggle_languages",
                icon: .arrowLeftArrowRight,
                defaultsKey: .toggleShortcut,
                action: { windowManager.toggleTranslationLanguages() }
            ),
            .pin: .init(
                titleKey: "pin",
                icon: .pin,
                defaultsKey: .pinShortcut,
                action: { windowManager.pin() }
            ),
            .hide: .init(
                titleKey: "hide",
                icon: .eyeSlash,
                defaultsKey: .hideShortcut,
                action: { windowManager.closeWindowOrExitSreenshot() }
            ),
            .increaseFontSize: .init(
                titleKey: "shortcut_increase_font",
                icon: .textformatAlt,
                defaultsKey: .increaseFontSize,
                action: {
                    if MyConfiguration.shared.fontSizeIndex < MyConfiguration.shared.fontSizes.count - 1 {
                        MyConfiguration.shared.fontSizeIndex += 1
                    }
                }
            ),
            .decreaseFontSize: .init(
                titleKey: "shortcut_decrease_font",
                icon: .textformatAlt,
                defaultsKey: .decreaseFontSize,
                action: {
                    if MyConfiguration.shared.fontSizeIndex > 0 {
                        MyConfiguration.shared.fontSizeIndex -= 1
                    }
                }
            ),
            .google: .init(
                titleKey: "open_in_google",
                icon: .magnifyingglass,
                defaultsKey: .googleShortcut,
                action: {
                    let window = windowManager.floatingWindow
                    window?.titleBar.googleButton.openLink()
                }
            ),
            .eudic: .init(
                titleKey: "open_in_eudic",
                icon: .bookClosed,
                defaultsKey: .eudicShortcut,
                action: {
                    let window = windowManager.floatingWindow
                    window?.titleBar.eudicButton.openLink()
                }
            ),
            .appleDic: .init(
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
