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
            KeyHolderDataItem(title: ShortcutType.clearInput.localizedStringKey(), type: .clearInput),
            KeyHolderDataItem(title: ShortcutType.clearAll.localizedStringKey(), type: .clearAll),
            KeyHolderDataItem(title: ShortcutType.copy.localizedStringKey(), type: .copy),
            KeyHolderDataItem(title: ShortcutType.copyFirstResult.localizedStringKey(), type: .copyFirstResult),
            KeyHolderDataItem(title: ShortcutType.focus.localizedStringKey(), type: .focus),
            KeyHolderDataItem(title: ShortcutType.play.localizedStringKey(), type: .play),
            KeyHolderDataItem(title: ShortcutType.retry.localizedStringKey(), type: .retry),
            KeyHolderDataItem(title: ShortcutType.toggle.localizedStringKey(), type: .toggle),
            KeyHolderDataItem(title: ShortcutType.pin.localizedStringKey(), type: .pin),
            KeyHolderDataItem(title: ShortcutType.hide.localizedStringKey(), type: .hide),
            KeyHolderDataItem(title: ShortcutType.increaseFontSize.localizedStringKey(), type: .increaseFontSize),
            KeyHolderDataItem(title: ShortcutType.decreaseFontSize.localizedStringKey(), type: .decreaseFontSize),
            KeyHolderDataItem(title: ShortcutType.google.localizedStringKey(), type: .google),
            KeyHolderDataItem(title: ShortcutType.eudic.localizedStringKey(), type: .eudic),
            KeyHolderDataItem(title: ShortcutType.appleDic.localizedStringKey(), type: .appleDic),
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
