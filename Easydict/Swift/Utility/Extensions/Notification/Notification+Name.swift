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

    static let languagePreferenceChanged = Notification.Name(I18nHelper.languagePreferenceChangedNotification)

    static let linkButtonUpdated = Notification.Name(EZQuickLinkButtonUpdateNotification)
}

@objc
extension NSNotification {
    public static let serviceHasUpdated = Notification.Name.serviceHasUpdated

    public static let openSettings = Notification.Name.openSettings

    public static let languagePreferenceChanged = Notification.Name.languagePreferenceChanged

    public static let linkButtonUpdated = Notification.Name.linkButtonUpdated
}

@objc
extension NotificationCenter {
    func postServiceUpdateNotification(
        serviceType: ServiceType = .init(rawValue: ""),
        windowType: EZWindowType = .none,
        autoQuery: Bool = false
    ) {
        let userInfo: [String: Any] = [
            EZServiceTypeKey: serviceType.rawValue,
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
