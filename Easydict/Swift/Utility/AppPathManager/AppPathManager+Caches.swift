//
//  AppPathManager+Caches.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
    /// The legacy CocoaLumberjack-compatible log root opened and exported by the menu bar.
    var mmLogRootDirectory: URL {
        cachesDirectory.appendingPathComponent("MMLogs", isDirectory: true)
    }

    var ocrImageDirectory: URL {
        mmLogRootDirectory.appendingPathComponent("Image", isDirectory: true)
    }

    var snipImageFileURL: URL {
        ocrImageDirectory.appendingPathComponent("snip_image.png", isDirectory: false)
    }

    var ocrCroppedImageFileURL: URL {
        ocrImageDirectory.appendingPathComponent("ocr_cropped_image.png", isDirectory: false)
    }

    /// The directory containing downloaded pronunciation audio.
    var audioCacheDirectory: URL {
        cachesDirectory.appendingPathComponent("audio", isDirectory: true)
    }
}
