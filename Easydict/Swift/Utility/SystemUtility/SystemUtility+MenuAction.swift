//
//  SystemUtility+MenuAction.swift
//  Easydict
//
//  Created by tisfeng on 2025/9/5.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation
import SelectedTextKit

// MARK: - PasteboardInsertionSnapshot

/// Captures app-owned pasteboard state without retaining insertion text.
struct PasteboardInsertionSnapshot {
    let items: [NSPasteboardItem]
    let changeCount: Int
    let shouldRestore: Bool
}

extension SystemUtility {
    /// Select all by menu action
    func selectAllByMenuAction() async {
        logInfo("Select all text by menu action selectAll")

        do {
            let selectAllMenuItem = try axManager.findMenuItem(.selectAll, requireEnabled: true)
            try selectAllMenuItem.performAction(.press)
        } catch {
            logError("Select all failed strategy=menu_action category=accessibility")
            return
        }
    }

    /// Insert text by menu action, validating the captured target immediately before dispatch.
    @MainActor
    func insertTextByMenuAction(
        _ text: String,
        validateBeforeDispatch: () throws -> (),
        restorePasteboard: Bool = true,
        restoreInterval: TimeInterval = minPasteboardInterval
    ) async throws {
        guard let snapshot = preparePasteboardForInsertion(text, restore: restorePasteboard) else {
            throw TextInsertionError.dispatchFailed(.menuAction)
        }

        do {
            try validateBeforeDispatch()
            let pasteItem = try axManager.findEnabledMenuItem(.paste)
            try validateBeforeDispatch()
            try pasteItem.performAction(kAXPressAction)
        } catch {
            await restorePasteboardIfUnchanged(snapshot, after: 0)
            throw error
        }

        await restorePasteboardIfUnchanged(snapshot, after: restoreInterval)
    }

    /// Writes one chunk to the general pasteboard and records a race-safe restore checkpoint.
    @MainActor
    func preparePasteboardForInsertion(_ text: String, restore: Bool)
        -> PasteboardInsertionSnapshot? {
        let pasteboard = NSPasteboard.general
        let savedItems = restore ? pasteboard.backupItems() : []
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            return nil
        }
        return PasteboardInsertionSnapshot(
            items: savedItems,
            changeCount: pasteboard.changeCount,
            shouldRestore: restore
        )
    }

    /// Restores only when no user or application has replaced the chunk on the pasteboard.
    @MainActor
    func restorePasteboardIfUnchanged(
        _ snapshot: PasteboardInsertionSnapshot,
        after interval: TimeInterval
    ) async {
        guard snapshot.shouldRestore else { return }
        await Task.sleep(seconds: interval)

        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount == snapshot.changeCount else {
            logInfo("Skip restoring insertion pasteboard because it changed")
            return
        }
        if snapshot.items.isEmpty {
            pasteboard.clearContents()
        } else {
            pasteboard.restoreItems(snapshot.items)
        }
    }
}
