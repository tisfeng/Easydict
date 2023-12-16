//
//  QueryServiceRecord.swift
//  Easydict
//
//  Created by tisfeng on 2023/12/13.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

@objc(EZQueryServiceRecord)
public class QueryServiceRecord: NSObject {
    @objc var serviceType: ServiceType = .apple
    @objc var queryCount = 0
    @objc var queryCharacterCount = 0

    @objc override public init() {}

    @objc init(serviceType: ServiceType = .apple, queryCount: Int = 0, queryCharacterCount: Int = 0) {
        self.serviceType = serviceType
        self.queryCount = queryCount
        self.queryCharacterCount = queryCharacterCount
    }
}
