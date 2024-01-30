//
//  ShortcutTab.swift
//  Easydict
//
//  Created by Sharker on 2024/1/21.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
struct ShortcutTab: View {
    var body: some View {
        Form {
            // Global shortcut
            GeneralShortcutSettingView()
            // In app shortcut
        }.formStyle(.grouped)
    }
}

@available(macOS 13, *)
#Preview {
    ShortcutTab()
}
