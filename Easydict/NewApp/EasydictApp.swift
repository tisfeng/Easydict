//
//  EasydictApp.swift
//  Easydict
//
//  Created by Kyle on 2023/12/28.
//  Copyright © 2023 izual. All rights reserved.
//

import Sparkle
import SwiftUI
import Defaults

@main
enum EasydictCmpatibilityEntry {
    static func main() {
        parseArmguments()
        if NewAppManager.shared.enable {
            EasydictApp.main()
        } else {
            _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        }
    }
}

struct EasydictApp: App {
    @NSApplicationDelegateAdaptor
    private var delegate: AppDelegate

    @Default(.hideMenuBarIcon)
    private var hideMenuBar

    private var menuBarImage: String {
        #if DEBUG
            "status_icon_debug"
        #else
            "status_icon"
        #endif
    }

    var body: some Scene {
        if #available(macOS 13, *) {
            MenuBarExtra(isInserted: $hideMenuBar.toggledValue) {
                MenuItemView()
            } label: {
                Label {
                    Text("Easydict")
                } icon: {
                    Image(menuBarImage)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                }
                .help("Easydict 🍃")
            }.menuBarExtraStyle(.menu)
            Settings {
                SettingView()
            }
        }
    }
}

extension Bool {
    var toggledValue: Bool {
        get { !self }
        mutating set { self = newValue.toggledValue }
    }
}
