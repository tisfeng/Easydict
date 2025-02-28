//
//  MainMenuCommand.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

struct EasydictMainMenu: Commands {
    // MARK: Internal

    var body: some Commands {
        // Shortcuts
        MainMenuShortcutCommand()

        // Override Help
        CommandGroup(replacing: .help) {
            Button("menu_feedback") {
                openURL(URL(string: "\(EZGithubRepoEasydictURL)/issues")!)
            }
        }

        // Override About
        CommandGroup(replacing: .appInfo) {
            Button {
                HostWindowManager.shared.showAboutWindow()
            } label: {
                Text("menubar.about")
            }
        }

        // Check for updates
        CommandGroup(after: .appInfo, addition: {
            Button {
                Configuration.shared.updater.checkForUpdates()
            } label: {
                Text("check_updates")
            }
        })
    }

    // MARK: Private

    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow
}
