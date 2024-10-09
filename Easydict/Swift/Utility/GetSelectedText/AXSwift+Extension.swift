//
//  AXSwift+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/8.
//  Copyright © 2024 izual. All rights reserved.
//

import AXSwift
import AXSwiftExt
import Foundation

func findEnabledCopyItemInFrontmostApp() -> UIElement? {
    guard checkIsProcessTrusted() else {
        logError("Process is not trusted for accessibility")
        return nil
    }

    let frontmostApp = NSWorkspace.shared.frontmostApplication
    guard let frontmostApp, let appElement = Application(frontmostApp) else {
        logError("Failed to get frontmost application: \(String(describing: frontmostApp))")
        return nil
    }

    guard let copyItem = appElement.findCopyMenuItem(),
          copyItem.isEnabled == true
    else {
        logInfo("No enabled copy item found in frontmost application: \(frontmostApp)")
        return nil
    }

    logInfo("Found enabled copy item in frontmost application: \(frontmostApp))")

    return copyItem
}

extension UIElement {
    /// Find the copy item element, identifier is "copy:", or title is "Copy".
    public func findCopyMenuItem() -> UIElement? {
        guard let menu, let menuChildren = menu.children else {
            logError("Menu children not found")
            return nil
        }

        // Try to get the 4th menu item, which usually is the Edit menu.
        if menuChildren.count >= 4 {
            let editMenu = menuChildren[3]
            logInfo("Checking Edit menu (4th menu item)")
            if let copyElement = findCopyMenuItemIn(editMenu) {
                return copyElement
            }
        }

        // If not found in Edit menu, search the entire menu.
        logInfo("Copy not found in Edit menu, searching entire menu")
        return findCopyMenuItemIn(menu)
    }

    /// Check if the element is a copy element, identifier is "copy:", means copy action selector.
    public var isCopyIdentifier: Bool {
        identifier == SystemMenuItem.copy.rawValue
    }

    /// Check if the element is a copy element, title is "Copy", "拷贝", "复制", "拷貝", "複製".
    public var isCopyTitle: Bool {
        guard let title = title else {
            return false
        }

        let copyTitles = [
            "Copy",
            "拷贝",
            "复制",
            "拷貝",
            "複製",
        ]
        return copyTitles.contains(title)
    }
}

/// NSRunningApplication extension description: localizedName (bundleIdentifier)
extension NSRunningApplication {
    open override var description: String {
        "\(localizedName ?? "") (\(bundleIdentifier ?? ""))"
    }
}

private func findCopyMenuItemIn(_ menuElement: UIElement) -> UIElement? {
    menuElement.deepFirst { element in
        guard let identifier = element.identifier else {
            return false
        }

        if element.isCopyIdentifier {
            logInfo("Found copy element by copy identifier: \(identifier)")
            return true
        }

        if element.cmdChar == "C", element.isCopyTitle {
            logInfo(
                "Found copy element by copy title in menu: \(element.title!), identifier: \(identifier)"
            )
            return true
        }
        return false
    }
}
