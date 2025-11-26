//
//  NSPasteboard+ObjCCompat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/25.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSPasteboard {
    /// Sets a string to the general pasteboard.
    ///
    /// - Parameter string: The string to set.
    @objc(mm_generalPasteboardSetString:)
    static func setString(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
}
