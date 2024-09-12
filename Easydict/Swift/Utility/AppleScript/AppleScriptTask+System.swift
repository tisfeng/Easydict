//
//  AppleScriptTask+System.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension AppleScriptTask {
    static func getAlertVolume() async throws -> Int32 {
        let script = "get alert volume of (get volume settings)"
        if let volumeString = try await runAppleScript(script),
           let volume = Int32(volumeString) {
            logInfo("AppleScript get alert volume: \(volume)")
            return volume
        }
        throw AppleScriptError.executionError(message: "Failed to get alert volume")
    }

    static func setAlertVolume(_ volume: Int) async throws {
        let script = "set volume alert volume \(volume)"
        try await runAppleScript(script)
        logInfo("AppleScript set alert volume: \(volume)")
    }
}
