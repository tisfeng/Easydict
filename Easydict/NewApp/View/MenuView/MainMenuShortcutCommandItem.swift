//
//  MainMenuShortcutCommandItem.swift
//  Easydict
//
//  Created by Sharker on 2024/2/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

struct MainMenuShortcutCommandDataItem: Identifiable {
    public var id: String { title }
    var title: String
    var type: ShortcutType
}

struct MainMenuShortcutCommandItem: View {
    public var dataItem: MainMenuShortcutCommandDataItem

    var body: some View {
        Button(LocalizedStringKey(dataItem.title)) {
            switch dataItem.type {
            case .clearInput:
                Shortcut.shared.clearInput()
            case .clearAll:
                Shortcut.shared.clearAll()
            case .copy:
                Shortcut.shared.shortcutCopy()
            case .copyFirstResult:
                Shortcut.shared.shortcutCopyFirstResult()
            case .focus:
                Shortcut.shared.shortcutFocus()
            case .play:
                Shortcut.shared.shortcutPlay()
            case .retry:
                Shortcut.shared.shortcutRetry()
            case .toggle:
                Shortcut.shared.shortcutToggle()
            case .pin:
                Shortcut.shared.shortcutPin()
            case .hide:
                Shortcut.shared.shortcutHide()
            case .increaseFontSize:
                Shortcut.shared.increaseFontSize()
            case .decreaseFontSize:
                Shortcut.shared.decreaseFontSize()
            case .google:
                Shortcut.shared.shortcutGoogle()
            case .eudic:
                Shortcut.shared.shortcutEudic()
            case .appleDic:
                Shortcut.shared.shortcutAppleDic()
            default: ()
            }
        }
        .keyboardShortcut(dataItem.type)

        if dataItem.type == .toggle || dataItem.type == .decreaseFontSize {
            Divider()
        }
    }
}
