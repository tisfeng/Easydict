//
//  AppPathManager+Cache.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
    /// The root directory for app-managed disposable data.
    var cacheDirectory: URL {
        appSupportDirectory.appendingPathComponent("cache", isDirectory: true)
    }

    /// The directory containing downloaded pronunciation audio.
    var audioCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("audio", isDirectory: true)
    }

    var mdictMetadataCacheDirectory: URL {
        cacheDirectory.appendingPathComponent("mdict-metadata", isDirectory: true)
    }

    /// The previous downloaded pronunciation audio location.
    var legacyAudioCacheDirectory: URL {
        cachesDirectory.appendingPathComponent("audio", isDirectory: true)
    }

    /// The previous MDict metadata cache location.
    var legacyMDictMetadataCacheDirectory: URL {
        appSupportDirectory.appendingPathComponent("mdict-metadata-cache", isDirectory: true)
    }
}
