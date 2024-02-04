//
//  GlobalShortcutSetting.swift
//  Easydict
//
//  Created by Sharker on 2024/1/1.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
extension ShortcutTab {
    struct GobalShortcutSettingView: View {
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
                    Text("input_translate")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .inputTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("snip_translate")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .snipTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("select_translate")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .selectTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("show_mini_window")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .showMiniWindow, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("silent_screenshot_ocr")
                    Spacer()
                    KeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
            } header: {
                Text("global_shortcut_setting")
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
