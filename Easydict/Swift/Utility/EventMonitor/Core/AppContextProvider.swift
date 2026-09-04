//
//  AppContextProvider.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - AppContextProvider

/// Provides application and selection context for event monitoring.
final class AppContextProvider {
    // MARK: Internal

    var frontmostApplication: NSRunningApplication? {
        NSWorkspace.shared.frontmostApplication ?? NSRunningApplication.current
    }

    func frontmostAppTriggerType(forceGetSelectedTextType: ForceGetSelectedTextType) -> EZTriggerType {
        let defaultAppModelList = defaultAppTriggerList(forceGetSelectedTextType: forceGetSelectedTextType)
        let userAppModelList = LocalStorage.shared().selectTextTypeAppModelList

        let appBundleID = frontmostApplication?.bundleIdentifier ?? ""
        // Cmd+A follows the same default auto-selection policy as mouse and
        // Shift triggers, while per-app configs can still opt out.
        let defaultType: EZTriggerType = [.doubleClick, .tripleClick, .dragged, .shift, .selectAllShortcut]

        var type = appSelectTextActionType(
            appBundleID: appBundleID,
            appModelList: defaultAppModelList,
            defaultType: defaultType
        )

        type = appSelectTextActionType(
            appBundleID: appBundleID,
            appModelList: userAppModelList,
            defaultType: type
        )

        return type
    }

    func recordSelectTextInfo(updateURL: @escaping (String?) -> ()) {
        let frontmostApp = frontmostApplication
        let bundleID = frontmostApp?.bundleIdentifier ?? ""
        Task {
            do {
                let urlString = try await AppleScriptTask.getCurrentTabURLFromBrowser(bundleID)
                logInfo("Get browser tab url: \(String(describing: urlString))")
                await MainActor.run {
                    updateURL(urlString)
                }
            } catch {
                logError("Failed to get browser tab url: \(error)")
            }
        }
    }

    func useAccessibilityForFirstTime() -> Bool {
        let defaults = UserDefaults.standard
        let hasUsedAutoSelectText = defaults.bool(forKey: Constants.hasUsedAutoSelectTextKey)
        if !hasUsedAutoSelectText {
            defaults.set(true, forKey: Constants.hasUsedAutoSelectTextKey)
            return true
        }
        return false
    }

    // MARK: Private

    private enum Constants {
        static let hasUsedAutoSelectTextKey = "kHasUsedAutoSelectTextKey"
        /// Screen mirroring hosts where drags represent remote touch input.
        /// See Easydict issue #1254, comment 5106847698:
        /// https://github.com/tisfeng/Easydict/issues/1254#issuecomment-5106847698
        static let screenMirrorIDs = [
            "com.apple.ScreenContinuity",
            "com.catchingnow.andfiles.fusionhost",
            "com.catchingnow.andfiles.phonescreenhost",
        ]
        /// 前台状态由截图浮层等辅助窗口占据的进程:此时鼠标事件是截图指令而不是划词,
        /// 自动取词会对其执行强制复制,备份/恢复剪贴板的窗口期会破坏刚写入的截图内容。
        static let overlayHelperIDs = [
            "com.electron.lark.helper",
        ]
    }

    private func appSelectTextActionType(
        appBundleID: String,
        appModelList: [AppTriggerConfig],
        defaultType: EZTriggerType
    )
        -> EZTriggerType {
        var triggerType = defaultType
        for appModel in appModelList where appModel.appBundleID == appBundleID {
            triggerType = appModel.triggerType
            logInfo("Hit app bundleID: \(appBundleID), triggerType: \(triggerType)")
        }
        return triggerType
    }

    private func defaultAppTriggerList(forceGetSelectedTextType: ForceGetSelectedTextType) -> [AppTriggerConfig] {
        var appTriggerList = (Constants.screenMirrorIDs + Constants.overlayHelperIDs).map {
            AppTriggerConfig(appBundleID: $0, triggerType: [])
        }
        if forceGetSelectedTextType == .simulatedShortcutCopy {
            let wechat = AppTriggerConfig()
            wechat.appBundleID = AppBundleIDs.weChat
            wechat.triggerType = [.doubleClick, .tripleClick]
            appTriggerList.append(wechat)

            if let mainBundleID = Bundle.main.bundleIdentifier, !mainBundleID.isEmpty {
                let currentApp = AppTriggerConfig(appBundleID: mainBundleID, triggerType: [])
                appTriggerList.append(currentApp)
            }
        }
        return appTriggerList
    }
}
