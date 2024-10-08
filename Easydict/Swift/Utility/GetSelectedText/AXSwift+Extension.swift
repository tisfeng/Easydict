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

func findEnabledCopyElementInFrontmostApp() -> UIElement? {
    guard checkIsProcessTrusted() else {
        logError("Process is not trusted for accessibility")
        return nil
    }

    let frontmostApp = NSWorkspace.shared.frontmostApplication
    guard let frontmostApp, let appElement = Application(frontmostApp) else {
        logError("Failed to get frontmost application: \(String(describing: frontmostApp))")
        return nil
    }

    guard let copyElement = appElement.findCopyElement(),
          copyElement.isEnabled == true
    else {
        logInfo("No enabled copy element found in frontmost application: \(frontmostApp)")
        return nil
    }

    logInfo("Found enabled copy element in frontmost application: \(frontmostApp))")

    return copyElement
}

extension UIElement {
    /// Find the copy element, identifier is "copy:", or title is "Copy".
    public func findCopyElement() -> UIElement? {
        menu?.deepFirst { element in
            guard let identifier = element.identifier else {
                return false
            }

            if element.isCopyIdentifier {
                logInfo("Found copy element by copy identifier: \(identifier)")
                return true
            }
            if element.isCopyTitle, element.cmdChar == "C" {
                logInfo("Found copy element by title: \(element.title!), identifier: \(identifier)")
                return true
            }
            return false
        }
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
