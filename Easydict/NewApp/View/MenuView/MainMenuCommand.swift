//
//  MainMenuCommand.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

struct EasyDictMainMenu: Commands {
    @Environment(\.openURL)
    private var openURL

    var body: some Commands {
        // shortcut
        MainMenuShortcutCommand()

        // Help
        CommandGroup(replacing: CommandGroupPlacement.help, addition: {
            Button("menu_feedback") {
                guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/issues") else {
                    return
                }
                openURL(versionURL)
            }
        })
    }
}
