//
//  Notification+Name.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/7.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let serviceHasUpdated = Notification.Name(EZServiceHasUpdatedNotification)
    static let openSettings = Notification.Name(EZOpenSettingsNotification)
    static let languagePreferenceChanged = Notification.Name(
        I18nHelper.languagePreferenceChangedNotification
    )
    static let linkButtonUpdated = Notification.Name(EZQuickLinkButtonUpdateNotification)
    static let didChangeFontSize = Notification.Name("didChangeFontSize")
    static let didChangeWindowConfiguration = Notification.Name("didChangeWindowConfiguration")
}

@objc
extension NSNotification {
    static let serviceHasUpdated = Notification.Name.serviceHasUpdated
    static let openSettings = Notification.Name.openSettings
    static let languagePreferenceChanged = Notification.Name.languagePreferenceChanged
    static let linkButtonUpdated = Notification.Name.linkButtonUpdated
    static let didChangeFontSize = Notification.Name.didChangeFontSize
    static let didChangeWindowConfiguration = Notification.Name.didChangeWindowConfiguration
}

@objc
extension NotificationCenter {
    func postServiceUpdateNotification(
        serviceType: String = "",
        windowType: EZWindowType = .none,
        autoQuery: Bool = false
    ) {
        let userInfo: [String: Any] = [
            EZServiceTypeKey: serviceType,
            EZWindowTypeKey: windowType.rawValue,
            EZAutoQueryKey: autoQuery,
        ]
        let notification = Notification(name: .serviceHasUpdated, userInfo: userInfo)
        post(notification)
    }

    func postServiceUpdateNotification() {
        postServiceUpdateNotification(autoQuery: false)
    }
}
