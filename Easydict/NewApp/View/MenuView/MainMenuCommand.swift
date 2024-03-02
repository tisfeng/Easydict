//
//  MainMenuCommand.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

struct EasyDictMainMenu: Commands {
    // MARK: Internal

    var body: some Commands {
        // shortcut
        MainMenuShortcutCommand()

        // Help
        CommandGroup(replacing: CommandGroupPlacement.help, addition: {
            Button("menu_feedback") {
                openURL(URL(string: "\(EZGithubRepoEasydictURL)/issues")!)
            }
        })
    }

    // MARK: Private

    @Environment(\.openURL) private var openURL
}
