//
//  AppleScriptUtils.swift
//  Easydict
//
//  Created by tisfeng on 2024/5/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - AppleScriptUtils

@objcMembers
class AppleScriptUtils: NSObject {
    static func getAlertVolume() -> Int32 {
        var error: NSDictionary?
        let script = """
            set alertVolume to alert volume of (get volume settings)
            return alertVolume
        """
        let appleScript = NSAppleScript(source: script)
        if let outputEvent = appleScript?.executeAndReturnError(&error) {
            return outputEvent.int32Value
        } else {
            if let error = error {
                logError(error.description)
            }
            return 0
        }
    }

    static func setAlertVolume(_ volume: Int) {
        var error: NSDictionary?
        let script = """
            tell application "System Events"
                set volume alert volume \(volume)
            end tell
        """
        let appleScript = NSAppleScript(source: script)
        appleScript?.executeAndReturnError(&error)
    }
}
