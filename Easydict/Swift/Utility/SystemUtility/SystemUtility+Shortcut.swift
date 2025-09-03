//
//  SystemUtility+Shortcut(.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/2.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import KeySender
import SelectedTextKit

extension SystemUtility {
    /// Select all text by shortcut key Command + A
    func selectAllByShortcut() async {
        logInfo("Select all text by hotkey Command + A")

        KeySender.selectAll()

        await Task.sleep(seconds: 0.05)
    }

    func insertTextByShortcut(_ text: String, preservePasteboard: Bool = true) async {
        await SelectedTextManager.shared.copyTextAndPaste(text, preservePasteboard: preservePasteboard)

        // Small delay to allow paste operation to complete
        await Task.sleep(seconds: 0.05)
    }
}
