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
        // MARK: Internal

        var body: some Commands {
            // shortcut Commands
            CommandMenu("shortcut") {
                ForEach(appShortcutCommandList) { item in
                    MainMenuShortcutCommandItem(dataItem: item)
                }
            }
        }

        // MARK: Private

        @State private var appShortcutCommandList = [
            MainMenuShortcutCommandDataItem(type: .clearInput),
            MainMenuShortcutCommandDataItem(type: .clearAll),
            MainMenuShortcutCommandDataItem(type: .copy),
            MainMenuShortcutCommandDataItem(type: .copyFirstResult),
            MainMenuShortcutCommandDataItem(type: .focus),
            MainMenuShortcutCommandDataItem(type: .play),
            MainMenuShortcutCommandDataItem(type: .retry),
            MainMenuShortcutCommandDataItem(type: .toggle),
            MainMenuShortcutCommandDataItem(type: .pin),
            MainMenuShortcutCommandDataItem(type: .hide),
            MainMenuShortcutCommandDataItem(type: .increaseFontSize),
            MainMenuShortcutCommandDataItem(type: .decreaseFontSize),
            MainMenuShortcutCommandDataItem(type: .google),
            MainMenuShortcutCommandDataItem(type: .eudic),
            MainMenuShortcutCommandDataItem(type: .appleDic),
        ]
    }
}
