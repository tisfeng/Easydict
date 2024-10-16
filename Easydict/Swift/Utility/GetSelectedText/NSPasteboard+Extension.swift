//
//  NSPasteboard+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/3.
//  Copyright © 2024 izual. All rights reserved.
//

import AppKit

private var kSavedItemsKey: UInt8 = 0

extension NSPasteboard {
    /// Perform temporary task, restore the pasteboard items after the task is completed.
    /// Restore delay is 0.05 second, to avoid pasteboard items being restored too early.
    @objc
    func performTemporaryTask(_ task: @escaping () -> ()) {
        performTemporaryTask(restoreDelay: 0.05, task: task)
    }

    func performTemporaryTask(restoreDelay: TimeInterval = 0, task: @escaping () -> ()) {
        saveCurrentContents()
        task()
        if restoreDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) {
                self.restoreOriginalContents()
            }
        } else {
            restoreOriginalContents()
        }
    }
}

extension NSPasteboard {
    @objc
    func saveCurrentContents() {
        var archivedItems = [NSPasteboardItem]()
        if let allItems = pasteboardItems {
            for item in allItems {
                let archivedItem = NSPasteboardItem()
                for type in item.types {
                    if let data = item.data(forType: type) {
                        archivedItem.setData(data, forType: type)
                    }
                }
                archivedItems.append(archivedItem)
            }
        }

        if !archivedItems.isEmpty {
            savedItems = archivedItems
        }
    }

    @objc
    func restoreOriginalContents() {
        if let items = savedItems {
            clearContents()
            writeObjects(items)
            savedItems = nil
        }
    }

    private var savedItems: [NSPasteboardItem]? {
        get {
            objc_getAssociatedObject(self, &kSavedItemsKey) as? [NSPasteboardItem]
        }
        set {
            objc_setAssociatedObject(self, &kSavedItemsKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

extension NSPasteboard {
    func setString(_ string: String?) {
        clearContents()
        if let string {
            setString(string, forType: .string)
        }
    }

    func string() -> String? {
        string(forType: .string)
    }
}
