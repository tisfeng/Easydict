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
            MainMenuShortcutCommandDataItem(title: ShortcutType.clearInput.localizedStringKey(), type: .clearInput),
            MainMenuShortcutCommandDataItem(title: ShortcutType.clearAll.localizedStringKey(), type: .clearAll),
            MainMenuShortcutCommandDataItem(title: ShortcutType.copy.localizedStringKey(), type: .copy),
            MainMenuShortcutCommandDataItem(title: ShortcutType.copyFirstResult.localizedStringKey(), type: .copyFirstResult),
            MainMenuShortcutCommandDataItem(title: ShortcutType.focus.localizedStringKey(), type: .focus),
            MainMenuShortcutCommandDataItem(title: ShortcutType.play.localizedStringKey(), type: .play),
            MainMenuShortcutCommandDataItem(title: ShortcutType.retry.localizedStringKey(), type: .retry),
            MainMenuShortcutCommandDataItem(title: ShortcutType.toggle.localizedStringKey(), type: .toggle),
            MainMenuShortcutCommandDataItem(title: ShortcutType.pin.localizedStringKey(), type: .pin),
            MainMenuShortcutCommandDataItem(title: ShortcutType.hide.localizedStringKey(), type: .hide),
            MainMenuShortcutCommandDataItem(title: ShortcutType.increaseFontSize.localizedStringKey(), type: .increaseFontSize),
            MainMenuShortcutCommandDataItem(title: ShortcutType.decreaseFontSize.localizedStringKey(), type: .decreaseFontSize),
            MainMenuShortcutCommandDataItem(title: ShortcutType.google.localizedStringKey(), type: .google),
            MainMenuShortcutCommandDataItem(title: ShortcutType.eudic.localizedStringKey(), type: .eudic),
            MainMenuShortcutCommandDataItem(title: ShortcutType.appleDic.localizedStringKey(), type: .appleDic),
        ]

        var body: some Commands {
            // shortcut Commands
            CommandMenu("shortcut") {
                ForEach(appShortcutCommandList) { item in
                    MainMenuShortcutCommandItem(dataItem: item)
                }
            }
        }
    }
}
