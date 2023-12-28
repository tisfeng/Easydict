//
//  MenuItemView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI

struct MenuItemView: View {
    var body: some View {
        settingItem
    }

    @ViewBuilder
    private var settingItem: some View {
        if #available(macOS 14.0, *) {
            SettingsLink()
        } else {
            Button {
                NSApplication.shared.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Text("Settings...")
            }
        }
    }
}

#Preview {
    MenuItemView()
}
