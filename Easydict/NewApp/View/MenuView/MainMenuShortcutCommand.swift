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
        @State private var appShortcutCommandList = [
            MainMenuShortcutCommandDataItem(title: "shortcut_clear_input", type: .clearInput),
            MainMenuShortcutCommandDataItem(title: "shortcut_clear_all", type: .clearAll),
            MainMenuShortcutCommandDataItem(title: "shortcut_copy", type: .copy),
            MainMenuShortcutCommandDataItem(title: "shortcut_copy_first_translated_text", type: .copyFirstResult),
            MainMenuShortcutCommandDataItem(title: "shortcut_focus", type: .focus),
            MainMenuShortcutCommandDataItem(title: "shortcut_play", type: .play),
            MainMenuShortcutCommandDataItem(title: "retry", type: .retry),
            MainMenuShortcutCommandDataItem(title: "toggle_languages", type: .toggle),
            MainMenuShortcutCommandDataItem(title: "pin", type: .pin),
            MainMenuShortcutCommandDataItem(title: "hide", type: .hide),
            MainMenuShortcutCommandDataItem(title: "shortcut_increase_font", type: .increaseFontSize),
            MainMenuShortcutCommandDataItem(title: "shortcut_decrease_font", type: .decreaseFontSize),
            MainMenuShortcutCommandDataItem(title: "open_in_google", type: .google),
            MainMenuShortcutCommandDataItem(title: "open_in_eudic", type: .eudic),
            MainMenuShortcutCommandDataItem(title: "open_in_apple_dictionary", type: .appleDic),
        ]

        var body: some Commands {
            // shortcut Commands
            CommandMenu("shortcut") {
                ForEach(appShortcutCommandList) { item in
                    MainMenuShortcutCommandItem(dataItem: item)
                    if item.title == "toggle_languages" || item.title == "shortcut_decrease_font" {
                        Divider()
                    }
                }
            }
        }
    }
}
