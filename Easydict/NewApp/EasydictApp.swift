//
//  EasydictApp.swift
//  Easydict
//
//  Created by Kyle on 2023/12/28.
//  Copyright © 2023 izual. All rights reserved.
//

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

class SPUUpdaterHelper: NSObject, SPUUpdaterDelegate {
    func feedURLString(for _: SPUUpdater) -> String? {
        var feedURLString = "https://raw.githubusercontent.com/tisfeng/Easydict/main/appcast.xml"
        #if DEBUG
            feedURLString = "http://localhost:8000/appcast.xml"
        #endif
        return feedURLString
    }
}

class SPUUserDriverHelper: NSObject, SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }
}

struct EasydictApp: App {
    @NSApplicationDelegateAdaptor
    var delegate: AppDelegate

    @AppStorage(kHideMenuBarIconKey)
    private var hideMenuBar = false

    private var menuBarImage: String {
        #if DEBUG
            "status_icon_debug"
        #else
            "status_icon"
        #endif
    }

    let userDriverHelper = SPUUserDriverHelper()
    let upadterHelper = SPUUpdaterHelper()

    private let updaterController: SPUStandardUpdaterController

    init() {
        // 参考 https://sparkle-project.org/documentation/programmatic-setup/
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: upadterHelper, userDriverDelegate: userDriverHelper)
    }

    var body: some Scene {
        if #available(macOS 13, *) {
            MenuBarExtra(isInserted: $hideMenuBar.toggledValue) {
                MenuItemView(updater: updaterController.updater)
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
