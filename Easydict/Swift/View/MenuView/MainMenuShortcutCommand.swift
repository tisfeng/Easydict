//
//  MainMenuShortcutCommand.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

extension EasydictMainMenu {
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
            MainMenuShortcutCommandDataItem(action: .clearInput),
            MainMenuShortcutCommandDataItem(action: .clearAll),
            MainMenuShortcutCommandDataItem(action: .copy),
            MainMenuShortcutCommandDataItem(action: .copyFirstResult),
            MainMenuShortcutCommandDataItem(action: .focus),
            MainMenuShortcutCommandDataItem(action: .play),
            MainMenuShortcutCommandDataItem(action: .retry),
            MainMenuShortcutCommandDataItem(action: .toggle),
            MainMenuShortcutCommandDataItem(action: .pin),
            MainMenuShortcutCommandDataItem(action: .hide),
            MainMenuShortcutCommandDataItem(action: .increaseFontSize),
            MainMenuShortcutCommandDataItem(action: .decreaseFontSize),
            MainMenuShortcutCommandDataItem(action: .google),
            MainMenuShortcutCommandDataItem(action: .eudic),
            MainMenuShortcutCommandDataItem(action: .appleDic),
        ]
    }
}
