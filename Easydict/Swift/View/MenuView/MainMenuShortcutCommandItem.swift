//
//  MainMenuShortcutCommandItem.swift
//  Easydict
//
//  Created by Sharker on 2024/2/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - MainMenuShortcutCommandDataItem

struct MainMenuShortcutCommandDataItem: Identifiable {
    // MARK: Public

    public var id: String { action.rawValue }

    // MARK: Internal

    var action: ShortcutAction
}

// MARK: - MainMenuShortcutCommandItem

struct MainMenuShortcutCommandItem: View {
    // MARK: Public

    public var dataItem: MainMenuShortcutCommandDataItem

    // MARK: Internal

    var body: some View {
        Button(LocalizedStringKey(dataItem.action.localizedStringKey())) {
            switch dataItem.action {
            case .clearInput:
                ShortcutManager.shared.clearInput()
            case .clearAll:
                ShortcutManager.shared.clearAll()
            case .copy:
                ShortcutManager.shared.shortcutCopy()
            case .copyFirstResult:
                ShortcutManager.shared.shortcutCopyFirstResult()
            case .focus:
                ShortcutManager.shared.shortcutFocus()
            case .play:
                ShortcutManager.shared.shortcutPlay()
            case .retry:
                ShortcutManager.shared.shortcutRetry()
            case .toggle:
                ShortcutManager.shared.shortcutToggle()
            case .pin:
                ShortcutManager.shared.shortcutPin()
            case .hide:
                ShortcutManager.shared.shortcutHide()
            case .increaseFontSize:
                ShortcutManager.shared.increaseFontSize()
            case .decreaseFontSize:
                ShortcutManager.shared.decreaseFontSize()
            case .google:
                ShortcutManager.shared.shortcutGoogle()
            case .eudic:
                ShortcutManager.shared.shortcutEudic()
            case .appleDic:
                ShortcutManager.shared.shortcutAppleDic()
            default: ()
            }
        }
        .keyboardShortcut(dataItem.action)

        if dataItem.action == .toggle || dataItem.action == .decreaseFontSize {
            Divider()
        }
    }
}
