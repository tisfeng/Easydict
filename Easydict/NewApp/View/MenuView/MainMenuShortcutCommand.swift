//
//  MainMenuShortcutCommand.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

extension EasyDictMainMenu {
    struct MainMenuShortcutCommand: Commands {
        var body: some Commands {
            // shortcut Commands
            CommandMenu("shortcut") {
                Button("shortcut_clear_input") {
                    Shortcut.shared.clearInput()
                }
                .keyboardShortcut(.clearInput)
                Button("shortcut_clear_all") {
                    Shortcut.shared.clearAll()
                }
                .keyboardShortcut(.clearAll)
                Button("shortcut_copy") {
                    Shortcut.shared.shortcutCopy()
                }
                .keyboardShortcut(.copy)
                Button("shortcut_copy_first_teanslated_text") {
                    Shortcut.shared.shortcutCopyFirstResult()
                }
                .keyboardShortcut(.copyFirstResult)
                Button("shortcut_focus") {
                    Shortcut.shared.shortcutFocus()
                }
                .keyboardShortcut(.focus)
                Button("shortcut_play") {
                    Shortcut.shared.shortcutPlay()
                }
                .keyboardShortcut(.play)
                Button("retry") {
                    Shortcut.shared.shortcutRetry()
                }
                .keyboardShortcut(.retry)
                Button("pin") {
                    Shortcut.shared.shortcutPin()
                }
                .keyboardShortcut(.pin)
                Button("hide") {
                    Shortcut.shared.shortcutHide()
                }
                .keyboardShortcut(.hide)
                Button("shortcut_increase_font") {
                    Shortcut.shared.increaseFontSize()
                }
                .keyboardShortcut(.increaseFontSize)
                Button("shortcut_decrease_font") {
                    Shortcut.shared.decreaseFontSize()
                }
                .keyboardShortcut(.decreaseFontSize)
                Button("open_in_google") {
                    Shortcut.shared.shortcutGoogle()
                }
                .keyboardShortcut(.google)
                Button("open_in_eudic") {
                    Shortcut.shared.shortcutEudic()
                }
                .keyboardShortcut(.eudic)
                Button("open_in_apple_dictionary") {
                    Shortcut.shared.shortcutAppleDic()
                }
                .keyboardShortcut(.appleDic)
            }
        }
    }
}
