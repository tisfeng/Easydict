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
    var savedItems: [NSPasteboardItem]? {
        get {
            objc_getAssociatedObject(self, &kSavedItemsKey) as? [NSPasteboardItem]
        }
        set {
            objc_setAssociatedObject(self, &kSavedItemsKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    func save() {
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

    func restore() {
        if let items = savedItems {
            clearContents()
            writeObjects(items)
            savedItems = nil
        }
    }

    /// Save the current pasteboard items, perform the task, and then restore the saved items.
    func onPrivateMode(restoreDelay: TimeInterval = 0, _ task: @escaping () -> ()) {
        save()
        task()
        if restoreDelay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) {
                self.restore()
            }
        } else {
            restore()
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
