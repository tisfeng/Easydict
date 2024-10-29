//
//  UpdateNotificationInfo.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/25.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - UpdateNotificationInfo

@objcMembers
public class UpdateNotificationInfo: NSObject {
    // MARK: Lifecycle

    init(windowType: EZWindowType, serviceType: ServiceType? = nil, autoQuery: Bool? = false) {
        self.windowType = windowType
        self.serviceType = serviceType
        self.autoQuery = autoQuery
    }

    // MARK: Internal

    let windowType: EZWindowType
    let serviceType: ServiceType?
    let autoQuery: Bool?
}
