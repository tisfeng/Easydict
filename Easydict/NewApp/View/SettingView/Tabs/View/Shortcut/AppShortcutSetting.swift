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
        @State var confictAlterMessage: ShortcutConfictAlertMessage = .init(title: "", message: "")
        var body: some View {
            let showAlter = Binding<Bool>(
                get: {
                    if !confictAlterMessage.message.isEmpty {
                        true
                    } else {
                        false
                    }
                }, set: { _ in
                }
            )
            Section {
                HStack {
                    Text("shortcut_clear_input")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .clearInput, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("shortcut_clear_all")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .clearAll, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("shortcut_copy")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .copy, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("shortcut_copy_first_teanslated_text")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .copyFirstResult, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("shortcut_focus")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .focus, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("shortcut_play")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .play, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("retry")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .retry, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("toggle_languages")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .toggle, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("pin")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .pin, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("hide")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .hide, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("shortcut_increase_font")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .increaseFontSize, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("shortcut_decrease_font")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .decreaseFontSize, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("open_in_google")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .google, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("open_in_eudic")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .eudic, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("open_in_apple_dictionary")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .appleDic, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
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
