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

// MARK: - EasydictCmpatibilityEntry

@main
enum EasydictCmpatibilityEntry {
    static func main() {
        parseArmguments()

        // Capturing crash logs must be placed first.
        MMCrash.registerHandler()
        EZLog.setupCrashService()
        EZLog.logAppInfo()

        // app launch
        EasydictApp.main()
    }
}

// MARK: - EasydictApp

struct EasydictApp: App {
    // MARK: Internal

    var body: some Scene {
        MenuBarExtra(isInserted: $hideMenuBar.toggledValue) {
            MenuItemView()
                .environmentObject(languageState)
                .environment(\.locale, .init(identifier: I18nHelper.shared.localizeCode))
        } label: {
            Label {
                Text("Easydict")
                    .openSettingsAccess() // trick way for open setting
                    .onReceive(
                        NotificationCenter.default.publisher(
                            for: Notification.Name.openSettings,
                            object: nil
                        )
                    ) { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            // calling `openSettings` immediately doesn't work so wait a quick moment
                            try? openSettings()
                        }
                    }
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
            // Override About button
            CommandGroup(replacing: .appInfo) {
                Button {
                    showAboutWindow()
                } label: {
                    Text("menubar.about")
                }
            }
        }

        Settings {
            SettingView().environmentObject(languageState).environment(
                \.locale,
                .init(identifier: I18nHelper.shared.localizeCode)
            )
        }
        Window("setting.about.acknowledgements", id: "acknowledgements") {
            AcknowListView()
        }
    }

    // MARK: Private

    @Environment(\.openSettings) private var openSettings

    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    // Use `@Default` will cause a purple warning and continuously call `set` of it.
    // I'm not sure why. Just leave `AppStorage` here.
    @AppStorage(Defaults.Key<Bool>.hideMenuBarIcon.name)
    private var hideMenuBar = Defaults.Key<Bool>.hideMenuBarIcon.defaultValue

    @Default(.selectedMenuBarIcon) private var menuBarIcon
    @StateObject private var languageState = LanguageState()
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
