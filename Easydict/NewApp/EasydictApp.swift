//
//  EasydictApp.swift
//  Easydict
//
//  Created by Kyle on 2023/12/28.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Sparkle
import SwiftUI

// MARK: - EasydictCmpatibilityEntry

@main
enum EasydictCmpatibilityEntry {
    static func main() {
        parseArmguments()
        if Configuration.shared.enableBetaNewApp {
            EasydictApp.main()
        } else {
            _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        }
    }
}

// MARK: - EasydictApp

struct EasydictApp: App {
    // MARK: Internal

    var body: some Scene {
        if #available(macOS 13, *) {
            MenuBarExtra(isInserted: $hideMenuBar.toggledValue) {
                MenuItemView()
            } label: {
                Label {
                    Text("Easydict")
                } icon: {
                    Image(menuBarIcon.rawValue)
                        .resizable()
                    #if DEBUG
                        .renderingMode(.original)
                    #else
                        .renderingMode(.template)
                    #endif
                        .scaledToFit()
                }
                .help("Easydict 🍃")
            }
            .menuBarExtraStyle(.menu)
            .commands {
                EasyDictMainMenu() // main menu
            }
            Settings {
                SettingView()
            }
        }
    }

    // MARK: Private

    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    // Use `@Default` will cause a purple warning and continuously call `set` of it.
    // I'm not sure why. Just leave `AppStorage` here.
    @AppStorage(Defaults.Key<Bool>.hideMenuBarIcon.name)
    private var hideMenuBar = Defaults.Key<Bool>.hideMenuBarIcon.defaultValue

    @Default(.selectedMenuBarIcon) private var menuBarIcon
}

extension Bool {
    var toggledValue: Bool {
        get { !self }
        mutating set { self = newValue.toggledValue }
    }
}

// MARK: - MenuBarIconType

enum MenuBarIconType: String, CaseIterable, Defaults.Serializable, Identifiable {
    case square = "square_menu_bar_icon"
    case rounded = "rounded_menu_bar_icon"

    // MARK: Internal

    var id: Self { self }
}
