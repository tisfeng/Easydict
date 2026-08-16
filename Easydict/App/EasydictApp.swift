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
        AnalyticsService.setupCrashService()
        AnalyticsService.logAppInfo()

        // Workaround for macOS 26 Tahoe WindowServer high GPU load: NSWindow subclasses
        // that directly override `_cornerMask` defeat AppKit's mask cache and force the
        // compositor to re-render every frame. Must run before any window is created.
        // See https://github.com/electron/electron/issues/48311
        if #available(macOS 26, *) {
            EZPatchWindowServerCornerMask()
        }

        // Workaround for macOS 26 Tahoe: AppKit's AutoFill heuristics launch
        // a per-app "AutoFill" helper process (SafariPlatformSupport.Helper)
        // on text input. Easydict needs no system AutoFill suggestions, so
        // disable the heuristics to keep that helper from spawning.
        if #available(macOS 26, *) {
            UserDefaults.standard.register(
                defaults: ["NSAutoFillHeuristicsEnabled": false]
            )
        }

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
                            // calling `openSettingsLegacy` immediately doesn't work so wait a quick moment
                            try? openSettingsLegacy()
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
            EasydictMainMenu() // main menu
        }

        Settings {
            SettingView()
                .environmentObject(languageState)
                .environment(\.locale, .init(identifier: I18nHelper.shared.localizeCode))
        }
    }

    // MARK: Private

    @Environment(\.openSettingsLegacy) private var openSettingsLegacy
    @Environment(\.openWindow) private var openWindow

    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    // Use `@Default` will cause a purple warning and continuously call `set` of it.
    // I'm not sure why. Just leave `AppStorage` here.
    @AppStorage(Defaults.Key<Bool>.hideMenuBarIcon.name)
    private var hideMenuBar = Defaults.Key<Bool>.hideMenuBarIcon.defaultValue

    @StateObject private var languageState = LanguageState()

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
