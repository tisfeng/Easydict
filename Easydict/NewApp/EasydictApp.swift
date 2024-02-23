//
//  EasydictApp.swift
//  Easydict
//
//  Created by Kyle on 2023/12/28.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SettingsAccess
import Sparkle
import SwiftUI

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

            Window("go_to_settings", id: "go_to_settings") {
                FakeViewToOpenSettingsInSonoma(title: "go_to_settings")
                    .openSettingsAccess()
            }
            .handlesExternalEvents(matching: ["settings"])
            .windowStyle(HiddenTitleBarWindowStyle())
            .windowResizability(.contentSize)

            Settings {
                SettingView()
            }
        }
    }
}

struct FakeViewToOpenSettingsInSonoma: View {
    @Environment(\.openSettings) private var openSettings
    var title: String

    var body: some View {
        ZStack {}
            .frame(width: 0, height: 0)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.appleEventReceived, object: nil)) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // calling `openSettings` immediately doesn't work so wait a quick moment
                    try? openSettings()
                    NSApplication.shared
                        .windows
                        .filter(\.canBecomeKey)
                        .filter { $0.title == title }
                        .forEach { $0.close() }
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
