//
//  MenuItemView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import SettingsAccess
import SFSafeSymbols
import Sparkle
import SwiftUI
import Vision
import ZipArchive

// MARK: - MenuItemView

struct MenuItemView: View {
    // MARK: Internal

    var body: some View {
        // .menuBarExtraStyle为 .menu 时某些控件可能会失效，只能显示内容（按照菜单项高度、图像以 template 方式渲染）无法交互
        // 比如 Stepper、Slider 等，像基本的 Button、Text、Divider、Image 等还是能正常显示的。
        // Button 和Label的systemImage是不会渲染的
        Group {
            versionItem

            Divider()

            inputItem.keyboardShortcut(.inputTranslate)
            screenshotItem.keyboardShortcut(.snipTranslate)
            selectWordItem.keyboardShortcut(.selectTranslate)
            pasteboardTranslateItem.keyboardShortcut(.pasteboardTranslate)
            polishAndReplaceItem.keyboardShortcut(.polishAndReplace)
            translateAndReplaceItem.keyboardShortcut(.translateAndReplace)
            miniWindowItem.keyboardShortcut(.showMiniWindow)

            Divider()

            silentScreenshotOCRItem.keyboardShortcut(.silentScreenshotOCR)

            if showOCRMenuItems {
                screenshotOCRItem
                pasteboardOCRItem
                showOCRWindowItem
            }

            Divider()

            settingItem.keyboardShortcut(.init(","))
            checkUpdateItem
            helpItem

            Divider()

            quitItem.keyboardShortcut(.init("q"))
        }
        .task {
            latestVersion = await fetchRepoLatestVersion(EZGithubRepoEasydict)
        }
    }

    // MARK: Private

    @ObservedObject private var store = MenuItemStore()

    @Default(.showOCRMenuItems) private var showOCRMenuItems

    @State private var currentVersion =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    @State private var latestVersion: String?

    @Environment(\.openURL) private var openURL

    private var versionString: String {
        let defaultLabel = "Easydict  \(currentVersion)"
        if let latestVersion,
           currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending {
            return defaultLabel + "  (✨\(latestVersion) )"
        } else {
            return defaultLabel
        }
    }

    // MARK: - Menu Items

    @ViewBuilder var inputItem: some View {
        menuItem(for: .inputTranslate)
    }

    @ViewBuilder private var screenshotItem: some View {
        menuItem(for: .snipTranslate)
    }

    @ViewBuilder private var selectWordItem: some View {
        menuItem(for: .selectTranslate)
    }

    @ViewBuilder private var pasteboardTranslateItem: some View {
        menuItem(for: .pasteboardTranslate)
    }

    @ViewBuilder private var translateAndReplaceItem: some View {
        menuItem(for: .translateAndReplace)
    }

    @ViewBuilder private var polishAndReplaceItem: some View {
        menuItem(for: .polishAndReplace)
    }

    @ViewBuilder private var miniWindowItem: some View {
        menuItem(for: .showMiniWindow)
    }

    @ViewBuilder private var silentScreenshotOCRItem: some View {
        menuItem(for: .silentScreenshotOCR)
    }

    @ViewBuilder private var screenshotOCRItem: some View {
        menuItem(for: .screenshotOCR)
    }

    @ViewBuilder private var pasteboardOCRItem: some View {
        menuItem(for: .pasteboardOCR)
    }

    @ViewBuilder private var showOCRWindowItem: some View {
        menuItem(for: .showOCRWindow)
    }

    // MARK: - Other Items

    /// Version item
    @ViewBuilder private var versionItem: some View {
        Button(versionString) {
            guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/releases") else {
                return
            }
            openURL(versionURL)
        }
    }

    /// Settings item
    @ViewBuilder private var settingItem: some View {
        let titleKey = LocalizedStringKey("Settings...")
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text(titleKey)
            } preAction: {
                logInfo("Open App Settings")
                NSApplication.shared.activateApp()
            } postAction: {
                // nothing to do
            }
        } else {
            Button(titleKey) {
                logInfo("Open App Settings")
                NSApplication.shared.activateApp()

                // Refer https://stackoverflow.com/a/77265223/8378840
                NSApplication.shared.sendAction(
                    Selector(("showSettingsWindow:")), to: nil, from: nil
                )
            }
        }
    }

    /// Check Updates item
    @ViewBuilder private var checkUpdateItem: some View {
        Button("check_updates") {
            logInfo("Check Updates")
            Configuration.shared.updater.checkForUpdates()
        }.disabled(!store.canCheckForUpdates)
    }

    /// Quit item
    @ViewBuilder private var quitItem: some View {
        Button("quit") {
            logInfo("Quit Application")
            NSApplication.shared.terminate(nil)
        }
    }

    /// Help item
    @ViewBuilder private var helpItem: some View {
        Menu("Help") {
            Button("Feedback") {
                logInfo("Open Feedback")
                guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/issues") else {
                    return
                }
                openURL(versionURL)
            }
            Button("Export Log") {
                exportLogAction()
            }
            Button("Log Directory") {
                logInfo("Open Log Directory")
                let logPath = MMManagerForLog.rootLogDirectory() ?? ""
                let directoryURL = URL(fileURLWithPath: logPath)
                NSWorkspace.shared.open(directoryURL)
            }
        }
    }

    // MARK: - Actions

    private func exportLogAction() {
        logInfo("Export Log")
        let logPath = MMManagerForLog.rootLogDirectory() ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"
        let dataString = dateFormatter.string(from: Date())
        let downloadDirectory = FileManager.default.urls(
            for: .downloadsDirectory, in: .userDomainMask
        )[0]
        let zipPath = downloadDirectory.appendingPathComponent("Easydict log \(dataString).zip")
            .path(percentEncoded: false)
        let success = SSZipArchive.createZipFile(
            atPath: zipPath,
            withContentsOfDirectory: logPath,
            keepParentDirectory: false
        )
        if success {
            NSWorkspace.shared.selectFile(zipPath, inFileViewerRootedAtPath: "")
        } else {
            logError("Export log failed")
        }
    }
}

// MARK: - MenuItemView Extensions

extension MenuItemView {
    /// Create a menu item from ShortcutAction configuration
    fileprivate func menuItem(for shortcutType: ShortcutAction) -> some View {
        MenuItemBuilder(
            data: MenuItemData(
                icon: shortcutType.icon,
                titleKey: shortcutType.localizedStringKey(),
                action: shortcutType.executeAction
            )
        )
    }
}

// MARK: - MenuItemData

/// Data structure for menu items
private struct MenuItemData {
    // MARK: Lifecycle

    init(icon: SFSymbol, titleKey: String, action: @escaping () -> ()) {
        self.icon = icon
        self.titleKey = titleKey
        self.action = action
    }

    // MARK: Internal

    let icon: SFSymbol
    let titleKey: String
    let action: () -> ()
}

// MARK: - MenuItemBuilder

/// Builder for creating consistent menu items
private struct MenuItemBuilder: View {
    let data: MenuItemData

    var body: some View {
        let titleKey = data.titleKey
        Button {
            logInfo("Menu Action: \(titleKey)")
            data.action()
        } label: {
            HStack {
                Image(systemSymbol: data.icon)
                Text(LocalizedStringKey(titleKey))
            }
        }
    }
}

// MARK: - MenuItemStore

final class MenuItemStore: ObservableObject {
    // MARK: Lifecycle

    init() {
        Configuration.shared.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    // MARK: Internal

    @Published var canCheckForUpdates = false
}

#Preview {
    MenuItemView()
}
