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
            dataItem.action.executeAction()
        }
        .keyboardShortcut(dataItem.action)

        if dataItem.action == .toggle || dataItem.action == .decreaseFontSize {
            Divider()
        }
    }
}
