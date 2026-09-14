//
//  AppPathManager+Caches.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
    /// The previous CocoaLumberjack-compatible log root.
    var legacyAppLogDirectory: URL {
        cachesDirectory.appendingPathComponent("MMLogs", isDirectory: true)
    }

    /// The previous downloaded pronunciation audio location.
    var legacyAudioCacheDirectory: URL {
        cachesDirectory.appendingPathComponent("audio", isDirectory: true)
    }
}
