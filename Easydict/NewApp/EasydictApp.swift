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

@main
enum EasydictCmpatibilityEntry {
    static func main() {
        parseArmguments()
        if #available(macOS 13, *), NewAppManager.shared.enable {
            EasydictApp.main()
        } else {
            _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
        }
    }
}

struct EasydictApp: App {
    @NSApplicationDelegateAdaptor
    private var delegate: AppDelegate

    // Use `@Default` will cause a purple warning and continuously call `set` of it.
    // I'm not sure why. Just leave `AppStorage` here.
    @AppStorage(Defaults.Key<Bool>.hideMenuBarIcon.name)
    private var hideMenuBar = Defaults.Key<Bool>.hideMenuBarIcon.defaultValue

    @Default(.selectedMenuBarIcon)
    private var menuBarIcon

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
}

extension Bool {
    var toggledValue: Bool {
        get { !self }
        mutating set { self = newValue.toggledValue }
    }
}

enum MenuBarIconType: String, CaseIterable, Defaults.Serializable, Identifiable {
    var id: Self { self }

    case square = "square_menu_bar_icon"
    case rounded = "rounded_menu_bar_icon"
}
