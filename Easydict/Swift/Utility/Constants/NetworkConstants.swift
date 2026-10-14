//
//  NetworkConstants.swift
//  Easydict
//
//  Created by tisfeng on 2026/10/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - NetworkConstants

/// Network constants shared by Swift and Objective-C.
@objcMembers
final class NetworkConstants: NSObject {
    /// Default timeout for translation requests, in seconds.
    static let timeoutInterval: TimeInterval = 15

    /// Mobile browser user agent for web translation APIs.
    static let userAgent =
        "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36"
}
