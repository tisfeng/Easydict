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

private let minPasteboardInterval: TimeInterval = 0.05

// MARK: - SystemUtility + Shortcut

extension SystemUtility {
    /// Select all text by shortcut key Command + A
    func selectAllByShortcut() async {
        logInfo("Select all text by hotkey Command + A")

        KeySender.selectAll()
        await Task.sleep(seconds: minPasteboardInterval)
    }

    /// Insert text by shortcut key, cmd+c and ctrl+v
    func insertTextByShortcut(
        _ text: String,
        restorePasteboard: Bool = true,
        restoreInterval: TimeInterval = minPasteboardInterval
    ) async {
        await PasteboardManager.shared.pasteText(
            text,
            restorePasteboard: restorePasteboard,
            restoreInterval: restoreInterval
        )
        await Task.sleep(seconds: minPasteboardInterval)
    }
}
