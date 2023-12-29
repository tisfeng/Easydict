//
//  SettingView.swift
//  Easydict
//
//  Created by Kyle on 2023/12/29.
//  Copyright © 2023 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
struct SettingView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("setting_general", systemImage: "gear") }
                .frame(width: 500, height: 400)
            PrivacyTab()
                .tabItem { Label("privacy", systemImage: "hand.raised.square") }
                .frame(width: 500, height: 400)
            AboutTab()
                .tabItem { Label("about", systemImage: "info.bubble") }
                .frame(width: 500, height: 400)
        }
    }
}

@available(macOS 13, *)
#Preview {
    SettingView()
}
