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
//                HStack {
//                    Text("shortcut_clear_all")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .selectTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("shortcut_copy")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .selectTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("shortcut_copy_first_teanslated_text")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .showMiniWindow, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("shortcut_focus")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("shortcut_play")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("retry")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("toggle_languages")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("pin")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("hide")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("shortcut_increase_font")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("shortcut_decrease_font")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("open_in_google")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("open_in_eudic")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
//                HStack {
//                    Text("open_in_apple_dictionary")
//                    Spacer()
//                    GlobalKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
//                }
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
