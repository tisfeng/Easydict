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

/// Minimum interval for pasteboard operations
let minPasteboardInterval: TimeInterval = 0.05

// MARK: - SystemUtility + Shortcut

extension SystemUtility {
    /// Select all text by shortcut key Command + A
    func selectAllByShortcut() async {
        logInfo("Select all text by hotkey Command + A")

        KeySender.selectAll()
        await Task.sleep(seconds: minPasteboardInterval)
    }

    /// Insert text by shortcut key, cmd+c and ctrl+v
    @MainActor
    func insertTextByShortcut(
        _ text: String,
        validateBeforeDispatch: () throws -> (),
        restorePasteboard: Bool = true,
        restoreInterval: TimeInterval = minPasteboardInterval
    ) async throws {
        guard let snapshot = preparePasteboardForInsertion(text, restore: restorePasteboard) else {
            throw TextInsertionError.dispatchFailed(.shortcut)
        }

        do {
            try validateBeforeDispatch()
            KeySender.paste()
        } catch {
            await restorePasteboardIfUnchanged(snapshot, after: 0)
            throw error
        }

        await restorePasteboardIfUnchanged(snapshot, after: restoreInterval)
    }
}
