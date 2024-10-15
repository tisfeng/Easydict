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
            logInfo("Checking the Edit(4th) menu")
            if let copyElement = findCopyMenuItemIn(editMenu) {
                return copyElement
            }
        }

        // If not found in Edit menu, search the entire menu.
        logInfo("Copy not found in Edit(4th) menu, searching entire menu")
        return findCopyMenuItemIn(menu)
    }

    /// Check if the element is a copy element, identifier is "copy:", means copy action selector.
    public var isCopyIdentifier: Bool {
        identifier == SystemMenuItem.copy.rawValue
    }

    /// Check if the element is a copy element, title is "Copy".
    public var isCopyTitle: Bool {
        guard let title = title else {
            return false
        }
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
            logInfo("Found copy item by copy identifier: \(identifier)")
            return true
        }

        if element.cmdChar == "C", element.isCopyTitle {
            logInfo("Found copy title item in menu: \(element.title!), identifier: \(identifier)")
            return true
        }
        return false
    }
}

/// Menu bar copy titles set, include most of the languages.
private let copyTitles: Set<String> = [
    "Copy", // English
    "拷贝", "复制", // Simplified Chinese
    "拷貝", "複製", // Traditional Chinese
    "コピー", // Japanese
    "복사", // Korean
    "Copier", // French
    "Copiar", // Spanish, Portuguese
    "Copia", // Italian
    "Kopieren", // German
    "Копировать", // Russian
    "Kopiëren", // Dutch
    "Kopiér", // Danish
    "Kopiera", // Swedish
    "Kopioi", // Finnish
    "Αντιγραφή", // Greek
    "Kopyala", // Turkish
    "Salin", // Indonesian
    "Sao chép", // Vietnamese
    "คัดลอก", // Thai
    "Копіювати", // Ukrainian
    "Kopiuj", // Polish
    "Másolás", // Hungarian
    "Kopírovat", // Czech
    "Kopírovať", // Slovak
    "Kopiraj", // Croatian, Serbian (Latin)
    "Копирај", // Serbian (Cyrillic)
    "Копиране", // Bulgarian
    "Kopēt", // Latvian
    "Kopijuoti", // Lithuanian
    "Copiază", // Romanian
    "העתק", // Hebrew
    "نسخ", // Arabic
    "کپی", // Persian
]
