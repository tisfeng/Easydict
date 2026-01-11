//
//  Notification+Name.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/7.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

/// Swift Notification.Name extensions
extension Notification.Name {
    static let serviceHasUpdated = Notification.Name("serviceHasUpdated")
    static let openSettings = Notification.Name(EZOpenSettingsNotification)
    static let languagePreferenceChanged = Notification.Name(
        I18nHelper.languagePreferenceChangedNotification
    )
    static let linkButtonUpdated = Notification.Name(EZQuickLinkButtonUpdateNotification)
    static let didChangeFontSize = Notification.Name("didChangeFontSize")
    static let didChangeWindowConfiguration = Notification.Name("didChangeWindowConfiguration")

    static let maxWindowHeightSettingsChanged = Notification.Name("maxWindowHeightSettingsChanged")

    // System dark mode change notification
    static let appleInterfaceThemeChanged = Notification.Name("AppleInterfaceThemeChangedNotification")

    // User app dark mode change notification
    static let appDarkModeDidChange = Notification.Name("AppDarkModeDidChange")
}

/// Objective-C Notification.Name extensions
@objc
extension NSNotification {
    static let serviceHasUpdated = Notification.Name.serviceHasUpdated
    static let openSettings = Notification.Name.openSettings
    static let languagePreferenceChanged = Notification.Name.languagePreferenceChanged
    static let linkButtonUpdated = Notification.Name.linkButtonUpdated
    static let didChangeFontSize = Notification.Name.didChangeFontSize
    static let didChangeWindowConfiguration = Notification.Name.didChangeWindowConfiguration
    static let maxWindowHeightSettingsChanged = Notification.Name.maxWindowHeightSettingsChanged
    static let appDarkModeDidChange = Notification.Name.appDarkModeDidChange
}

// MARK: - UserInfoKey

@objcMembers
class UserInfoKey: NSObject {
    /// UserInfo key for dark mode state in appDarkModeDidChange notification
    static let isDark = "isDark"

    static let windowType = "windowType"
    static let serviceType = "serviceType"
    static let autoQuery = "autoQuery"
}

@objc
extension NotificationCenter {
    func postServiceUpdateNotification(
        serviceType: String = "",
        windowType: EZWindowType = .none,
        autoQuery: Bool = false
    ) {
        let userInfo: [String: Any] = [
            UserInfoKey.serviceType: serviceType,
            UserInfoKey.windowType: windowType.rawValue,
            UserInfoKey.autoQuery: autoQuery,
        ]
        let notification = Notification(name: .serviceHasUpdated, userInfo: userInfo)
        post(notification)
    }

    func postServiceUpdateNotification() {
        postServiceUpdateNotification(autoQuery: false)
    }

    /// Post dark mode change notification
    func postDarkModeDidChangeNotification(isDark: Bool) {
        let notification = Notification(
            name: .appDarkModeDidChange,
            userInfo: [UserInfoKey.isDark: isDark]
        )
        post(notification)
    }
}
