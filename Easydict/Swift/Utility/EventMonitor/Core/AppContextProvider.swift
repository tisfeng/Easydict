//
//  AppContextProvider.swift
//  Scoco
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
        let defaultType: EZTriggerType = [.doubleClick, .tripleClick, .dragged, .shift]

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
        var appTriggerList: [AppTriggerConfig] = []
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
