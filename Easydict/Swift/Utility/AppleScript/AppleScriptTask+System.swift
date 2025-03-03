//
//  AppleScriptTask+System.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension AppleScriptTask {
    /// Get alert volume of volume settings, cost ~0.1s
    static func alertVolume() async throws -> Int {
        let script = "get alert volume of (get volume settings)"
        if let volumeString = try await runAppleScript(script),
           let volume = Int(volumeString) {
            logInfo("AppleScript get alert volume: \(volume)")
            return volume
        }
        throw QueryError(type: .appleScript, message: "Failed to get alert volume")
    }

    /// Set alert volume of volume settings, cost ~0.1s
    static func setAlertVolume(_ volume: Int) async throws {
        logInfo("AppleScript set alert volume: \(volume)")
        let script = "set volume alert volume \(volume)"
        try await runAppleScript(script)
    }

    /// Mute the alert volume and return the previous volume
    /// - Returns: The previous alert volume before muting
    static func muteAlertVolume() async throws -> Int {
        logInfo("AppleScript muted alert volume")
        let previousVolume = try await setAlertVolumeAndReturnPrevious(0)
        return previousVolume
    }

    /// Set alert volume and return the previous volume
    /// - Parameter volume: The new volume to set
    /// - Returns: The previous alert volume
    static func setAlertVolumeAndReturnPrevious(_ volume: Int) async throws -> Int {
        let script = """
        tell application "System Events"
            set currentVolume to get alert volume of (get volume settings)
            set volume alert volume \(volume)
            return currentVolume
        end tell
        """

        if let result = try await runAppleScript(script),
           let previousVolume = Int(result) {
            logInfo("AppleScript set alert volume from \(previousVolume) to \(volume)")
            return previousVolume
        }

        throw QueryError(
            type: .appleScript, message: "Failed to set alert volume and get previous volume"
        )
    }
}
