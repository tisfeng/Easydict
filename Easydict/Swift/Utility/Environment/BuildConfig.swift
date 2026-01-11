//
//  BuildConfig.swift
//  Easydict
//
//  Created by isfeng on 2025/12/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - BuildConfig

enum BuildConfig {
    #if DEBUG
    static let isDebug = true
    #else
    static let isDebug = false
    #endif
}
