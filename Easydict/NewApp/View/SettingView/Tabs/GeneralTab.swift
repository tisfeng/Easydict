//
//  GeneralTab.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
struct GeneralTab: View {
    var body: some View {
        Form {
            // shortcut setting
            ShortcutSettingView()
            // other
            OtherSettingView()
        }
        .formStyle(.grouped)
    }
}

@available(macOS 13, *)
#Preview {
    GeneralTab()
}
