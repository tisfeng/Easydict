//
//  SystemUtility+MenuAction.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/5.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import SelectedTextKit

extension SystemUtility {
    /// Select all by menu action
    func selectAllByMenuAction() async {
        logInfo("Select all text by menu action selectAll")

        do {
            let selectAllMenuItem = try axManager.findMenuItem(.selectAll, requireEnabled: true)
            try selectAllMenuItem.performAction(.press)
        } catch {
            logError("Failed to find Select All menu item: \(error)")
            return
        }
    }

    /// Insert text by menu action
    func insertTextByMenuAction(
        _ text: String,
        restorePasteboard: Bool = true,
        restoreInterval: TimeInterval = minPasteboardInterval
    ) async {
        await pasteboardManager.pasteText(text, restorePasteboard: restorePasteboard, restoreInterval: restoreInterval)
    }
}
