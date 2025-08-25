//
//  ShortcutManager+Menu.swift
//  Easydict
//
//  Created by Sharker on 2024/2/7.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

extension ShortcutManager {
    /// Update shortcut menu
    func updateMenu(_ type: ShortcutAction) {
        let shortcutTitle = String(localized: LocalizedStringResource(stringLiteral: type.localizedStringKey()))
        let menuTitle = String(localized: LocalizedStringResource(stringLiteral: "shortcut"))
        let shortcutMenu = NSApp.mainMenu?.items.first(where: { $0.title == menuTitle })
        let clearInput = shortcutMenu?.submenu?.items.first(where: { $0.title == shortcutTitle })
        clearInput?.keyEquivalent = ""
    }
}
