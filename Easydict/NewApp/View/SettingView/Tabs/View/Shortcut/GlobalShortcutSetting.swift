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
        @State private var shortcutDataList = [
            KeyHolderDataItem(title: ShortcutType.inputTranslate.localizedStringKey(), type: .inputTranslate),
            KeyHolderDataItem(title: ShortcutType.snipTranslate.localizedStringKey(), type: .snipTranslate),
            KeyHolderDataItem(title: ShortcutType.selectTranslate.localizedStringKey(), type: .selectTranslate),
            KeyHolderDataItem(title: ShortcutType.showMiniWindow.localizedStringKey(), type: .showMiniWindow),
            KeyHolderDataItem(title: ShortcutType.silentScreenshotOcr.localizedStringKey(), type: .silentScreenshotOcr),
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
