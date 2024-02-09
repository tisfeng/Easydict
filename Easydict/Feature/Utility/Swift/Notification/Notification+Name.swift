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
}

@objc public extension NSNotification {
    static let serviceHasUpdated = Notification.Name.serviceHasUpdated
}
