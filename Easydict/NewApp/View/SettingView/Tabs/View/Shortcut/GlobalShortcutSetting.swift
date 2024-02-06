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
    struct GlobalShortcutSettingView: View {
        @State var confictAlterMessage: ShortcutConfictAlertMessage = .init(title: "", message: "")
        private var shortcutDataList = [
            KeyHolderDataItem(title: "input_translate", type: .inputTranslate),
            KeyHolderDataItem(title: "snip_translate", type: .snipTranslate),
            KeyHolderDataItem(title: "select_translate", type: .selectTranslate),
            KeyHolderDataItem(title: "show_mini_window", type: .showMiniWindow),
            KeyHolderDataItem(title: "silent_screenshot_ocr", type: .silentScreenshotOcr),
        ]
        var body: some View {
            let showAlter = Binding<Bool>(
                get: {
                    !confictAlterMessage.message.isEmpty
                }, set: { _ in
                }
            )
            Section {
                ForEach(shortcutDataList) { item in
                    KeyHolderRowView(title: item.title, type: item.type, confictAlterMessage: $confictAlterMessage)
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
