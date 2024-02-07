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
            KeyHolderDataItem(type: .clearInput),
            KeyHolderDataItem(type: .clearAll),
            KeyHolderDataItem(type: .copy),
            KeyHolderDataItem(type: .copyFirstResult),
            KeyHolderDataItem(type: .focus),
            KeyHolderDataItem(type: .play),
            KeyHolderDataItem(type: .retry),
            KeyHolderDataItem(type: .toggle),
            KeyHolderDataItem(type: .pin),
            KeyHolderDataItem(type: .hide),
            KeyHolderDataItem(type: .increaseFontSize),
            KeyHolderDataItem(type: .decreaseFontSize),
            KeyHolderDataItem(type: .google),
            KeyHolderDataItem(type: .eudic),
            KeyHolderDataItem(type: .appleDic),
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
                    KeyHolderRowView(title: item.type.localizedStringKey(), type: item.type, confictAlterMessage: $confictAlterMessage)
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
