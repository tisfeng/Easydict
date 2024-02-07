//
//  Shortcut+Menu.swift
//  Easydict
//
//  Created by Sharker on 2024/2/7.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

extension Shortcut {
    func updateMenu(_ type: ShortcutType) { // update shortcut menu
        let shortcutTitle = String.localizedString(for: LocalizedStringKey(type.localizedStringKey()).stringKey ?? "")
        let shortcutMenu = NSApp.mainMenu?.items.first(where: { $0.title == "Shortcut" })
        let clearInput = shortcutMenu?.submenu?.items.first(where: { $0.title == shortcutTitle })
        clearInput?.keyEquivalent = ""
    }
}
