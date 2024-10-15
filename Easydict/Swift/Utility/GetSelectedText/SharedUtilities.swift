//
//  SharedUtilities.swift
//  Easydict
//
//  Created by tisfeng on 10/15/24.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

/// Shared utilities for objc and swift.
@objc
public class SharedUtilities: NSObject {
    /// Sync poll task, if task is true, return true, else continue polling.
    ///
    /// - Warning: ⚠️ This method will block the current thread, only use when necessary.
    /// - Returns: true if the task succeeded, false if it timed out.
    @objc
    @discardableResult
    public static func pollTask(
        _ task: @escaping () -> Bool,
        every interval: TimeInterval = 0.005,
        timeout: TimeInterval = 0.1,
        timeoutCallback: @escaping () -> () = {}
    )
        -> Bool {
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            if task() {
                return true
            }
            Thread.sleep(forTimeInterval: interval)
        }
        timeoutCallback()
        logInfo("pollTask timeout call back")
        return false
    }
}
