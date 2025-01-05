//
//  Constants.swift
//  Easydict
//
//  Created by tisfeng on 2024/9/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - Constants

@objcMembers
class Constants: NSObject {
    // Easydict translate shortcut name.
    static let easydictTranslatShortcutName = "Easydict-Translate-V1.2.0"
}

extension String {
    // Acknowledgements window id for macOS 15.
    static let acknowledgementsWindowId_15Plus = "setting.about.acknowledgements_15_plus"
    
    // Acknowledgements window id.
    static let acknowledgementsWindowId = "setting.about.acknowledgements"

    // About window id.
    static let aboutWindowId = "setting.about"
}
