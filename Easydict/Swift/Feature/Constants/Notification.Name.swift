//
//  Notification.Name.swift
//  Easydict
//
//  Created by tisfeng on 2024/6/11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let didChangeFontSize = Notification.Name("didChangeFontSize")
    static let didChangeSettingReplaceNewlineWithSpaceToggleValue = Notification
        .Name("didChangeSettingReplaceNewlineWithSpaceToggleValue")
}

// MARK: - NotificationName

@objc
class NotificationName: NSObject {
    @objc static let didChangeFontSize = Notification.Name.didChangeFontSize
    @objc static let didChangeSettingReplaceNewlineWithSpaceToggleValue = Notification.Name
        .didChangeSettingReplaceNewlineWithSpaceToggleValue
}
