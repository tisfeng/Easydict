//
//  SharedUtilities.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/3.
//  Copyright © 2024 izual. All rights reserved.
//

import AXSwift
import AXSwiftExt
import Carbon
import KeySender
import SelectedTextKit

// MARK: - SharedUtilities

/// Shared utilities for objc.
@objcMembers
class SharedUtilities: NSObject {
    static func getSelectedText() async throws -> String? {
        try await SelectedTextKit.getSelectedText()
    }

    static func getSelectedTextByMenuBarActionCopy() async throws -> String? {
        try await SelectedTextKit.getSelectedTextByMenuBarActionCopy()
    }

    static func getSelectedTextByShortcutCopy() async throws -> String? {
        await SelectedTextKit.getSelectedTextByShortcutCopy()
    }

    /// Copy text and paste text.
    static func copyTextAndPaste(_ text: String) async {
        await SelectedTextKit.copyTextAndPaste(text)
    }
}
