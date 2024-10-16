//
//  SharedUtilities.swift
//  Easydict
//
//  Created by tisfeng on 10/15/24.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - SharedUtilities

/// Shared utilities for objc and swift.
@objc
public class SharedUtilities: NSObject {}

/// Sync poll task, if task is true, return true, else continue polling.
///
/// - Warning: ⚠️ This method will block the current thread, only use when necessary.
func pollTask(
    _ task: @escaping () -> Bool,
    every interval: TimeInterval = 0.005,
    timeout: TimeInterval = 0.1,
    timeoutCallback: @escaping () -> () = {}
) {
    let startTime = Date()
    while Date().timeIntervalSince(startTime) < timeout {
        if task() {
            return
        }
        Thread.sleep(forTimeInterval: interval)
    }
    timeoutCallback()
    logInfo("pollTask timeout call back")
}
