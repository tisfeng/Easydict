//
//  MenuItemView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SettingsAccess
import Sparkle
import SwiftUI
import ZipArchive

@available(macOS 13, *)
final class MenuItemStore: ObservableObject {
    @Published var canCheckForUpdates = false

    init() {
        Configuration.shared.updater
            .publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

@available(macOS 13, *)
struct MenuItemView: View {
    @ObservedObject private var store = MenuItemStore()

    var body: some View {
        // ️.menuBarExtraStyle为 .menu 时某些控件可能会失效 ，只能显示内容（按照菜单项高度、图像以 template 方式渲染）无法交互 ，比如 Stepper、Slider 等，像基本的 Button、Text、Divider、Image 等还是能正常显示的。
        // Button 和Label的systemImage是不会渲染的
        Group {
            versionItem
            Divider()
            inputItem
                .keyboardShortcut(.inputTranslate)
            screenshotItem
                .keyboardShortcut(.snipTranslate)
            selectWordItem
                .keyboardShortcut(.selectTranslate)
            miniWindowItem
                .keyboardShortcut(.showMiniWindow)
            Divider()
            ocrItem
                .keyboardShortcut(.silentScreenshotOcr)
            Divider()
            settingItem
                .keyboardShortcut(.init(","))
            checkUpdateItem
            helpItem
            Divider()
            quitItem
                .keyboardShortcut(.init("q"))
        }
        .task {
            let version = await EZMenuItemManager.shared().fetchRepoLatestVersion(EZGithubRepoEasydict)
            await MainActor.run {
                latestVersion = version
            }
        }
    }

    @State
    private var currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""

    @State
    private var latestVersion: String?

    @Environment(\.openURL)
    private var openURL

    @ViewBuilder
    private var versionItem: some View {
        Button(versionString) {
            guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/releases") else {
                return
            }
            openURL(versionURL)
        }
    }

    private var versionString: String {
        let defaultLabel = "Easydict  \(currentVersion)"
        if let latestVersion,
           currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
        {
            return defaultLabel + "  (✨ \(latestVersion)"
        } else {
            return defaultLabel
        }
    }

    @ViewBuilder
    private var settingItem: some View {
        if #available(macOS 14.0, *) {
            SettingsLink {
                Text("Settings...")
            } preAction: {
                NSLog("打开设置")
                NSApp.activate(ignoringOtherApps: true)
            } postAction: {
                // nothing to do
            }
        } else {
            Button("Settings...") {
                NSLog("打开设置")
                NSApp.activate(ignoringOtherApps: true)
                NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
    }

    // MARK: - List of functions

    @ViewBuilder
    private var inputItem: some View {
        Button {
            NSLog("输入翻译")
            EZWindowManager.shared().inputTranslate()
        } label: {
            HStack {
                Image(systemName: "keyboard")
                Text("menu_input_translate")
            }
        }
    }

    @ViewBuilder
    private var screenshotItem: some View {
        Button {
            NSLog("截图翻译")
            EZWindowManager.shared().snipTranslate()
        } label: {
            HStack {
                Image(systemName: "camera.viewfinder")
                Text("menu_screenshot_Translate")
            }
        }
    }

    @ViewBuilder
    private var selectWordItem: some View {
        Button {
            NSLog("划词翻译")
            EZWindowManager.shared().selectTextTranslate()
        } label: {
            HStack {
                Image(systemName: "highlighter")
                Text("menu_selectWord_Translate")
            }
        }
    }

    @ViewBuilder
    private var miniWindowItem: some View {
        Button {
            NSLog("显示迷你窗口")
            EZWindowManager.shared().showMiniFloatingWindow()
        } label: {
            HStack {
                Image(systemName: "dock.rectangle")
                Text("menu_show_mini_window")
            }
        }
    }

    @ViewBuilder
    private var ocrItem: some View {
        Button {
            NSLog("静默截图OCR")
            EZWindowManager.shared().screenshotOCR()
        } label: {
            HStack {
                Image(systemName: "camera.metering.spot")
                Text("menu_silent_screenshot_OCR")
            }
        }
    }

    // MARK: - Setting

    @ViewBuilder
    private var checkUpdateItem: some View {
        Button("check_updates") {
            NSLog("检查更新")
            Configuration.shared.updater.checkForUpdates()
        }.disabled(!store.canCheckForUpdates)
    }

    @ViewBuilder
    private var quitItem: some View {
        Button("quit") {
            NSLog("退出应用")
            NSApplication.shared.terminate(nil)
        }
    }

    @ViewBuilder
    private var helpItem: some View {
        Menu("Help") {
            Button("Feedback") {
                guard let versionURL = URL(string: "\(EZGithubRepoEasydictURL)/issues") else {
                    return
                }
                openURL(versionURL)
            }
            Button("Export Log") {
                exportLogAction()
            }
            Button("Log Directory") {
                NSLog("日志目录")
                let logPath = MMManagerForLog.rootLogDirectory() ?? ""
                let directoryURL = URL(fileURLWithPath: logPath)
                NSWorkspace.shared.open(directoryURL)
            }
        }
    }

    private func exportLogAction() {
        NSLog("导出日志")
        let logPath = MMManagerForLog.rootLogDirectory() ?? ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH-mm-ss-SSS"
        let dataString = dateFormatter.string(from: Date())
        let downloadDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let zipPath = downloadDirectory.appendingPathComponent("Easydict log \(dataString).zip").path(percentEncoded: false)
        let success = SSZipArchive.createZipFile(atPath: zipPath, withContentsOfDirectory: logPath, keepParentDirectory: false)
        if success {
            NSWorkspace.shared.selectFile(zipPath, inFileViewerRootedAtPath: "")
        } else {
            MMLogInfo("导出日志失败")
        }
    }
}

@available(macOS 13, *)
#Preview {
    MenuItemView()
}
