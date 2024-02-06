//
//  AppShortcutSetting.swift
//  Easydict
//
//  Created by Sharker on 2024/2/4.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
extension ShortcutTab {
    struct AppShortcutSettingView: View {
        @State private var shortcutDataList = [
            KeyHolderDataItem(title: "shortcut_clear_input", type: .clearInput),
            KeyHolderDataItem(title: "shortcut_clear_all", type: .clearAll),
            KeyHolderDataItem(title: "shortcut_copy", type: .copy),
            KeyHolderDataItem(title: "shortcut_copy_first_teanslated_text", type: .copyFirstResult),
            KeyHolderDataItem(title: "shortcut_focus", type: .focus),
            KeyHolderDataItem(title: "shortcut_play", type: .play),
            KeyHolderDataItem(title: "retry", type: .retry),
            KeyHolderDataItem(title: "toggle_languages", type: .toggle),
            KeyHolderDataItem(title: "pin", type: .pin),
            KeyHolderDataItem(title: "hide", type: .hide),
            KeyHolderDataItem(title: "shortcut_increase_font", type: .increaseFontSize),
            KeyHolderDataItem(title: "shortcut_decrease_font", type: .decreaseFontSize),
            KeyHolderDataItem(title: "open_in_google", type: .google),
            KeyHolderDataItem(title: "open_in_eudic", type: .increaseFontSize),
            KeyHolderDataItem(title: "open_in_apple_dictionary", type: .increaseFontSize),
        ]
        @State var confictAlterMessage: ShortcutConfictAlertMessage = .init(title: "", message: "")
        var body: some View {
            let showAlter = Binding<Bool>(
                get: {
                    !confictAlterMessage.message.isEmpty
                },
                set: { _ in }
            )
            Section {
                ForEach(shortcutDataList) { item in
                    KeyHolderRowView(title: item.title, type: item.type, confictAlterMessage: $confictAlterMessage)
                }
            } header: {
                Text("app_shortcut_setting")
            }

            .alert(String(localized: "shortcut_confict \(confictAlterMessage.title)"),
                   isPresented: showAlter,
                   presenting: confictAlterMessage)
            { _ in
                Button(String(localized: "shortcut_confict_confirm")) {
                    confictAlterMessage = ShortcutConfictAlertMessage(title: "", message: "")
                }
            } message: { message in
                Text(message.message)
            }
        }
    }
}
