//
//  ShortcutConfictAlertMessage.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/25.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - ShortcutConfictAlertMessage

// Confict Message
public struct ShortcutConfictAlertMessage: Identifiable {
    // MARK: Public

    public var id: String { message }

    // MARK: Internal

    var title: String
    var message: String
}
