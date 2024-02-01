//
//  GeneralShortcutSetting.swift
//  Easydict
//
//  Created by Sharker on 2024/1/1.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
extension ShortcutTab {
    struct GeneralShortcutSettingView: View {
        @State var confictAlterMessage: ShortcutConfictAlertMessage = .init(message: "")

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
                    GeneralKeyHolderWrapper(shortcutType: .inputTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("snip_translate")
                    Spacer()
                    GeneralKeyHolderWrapper(shortcutType: .snipTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("select_translate")
                    Spacer()
                    GeneralKeyHolderWrapper(shortcutType: .selectTranslate, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("show_mini_window")
                    Spacer()
                    GeneralKeyHolderWrapper(shortcutType: .showMiniWindow, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
                HStack {
                    Text("silent_screenshot_ocr")
                    Spacer()
                    GeneralKeyHolderWrapper(shortcutType: .silentScreenshotOcr, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
                }
            } header: {
                Text("global_shortcut_setting")
            }

            .alert(String(localized: "shortcut_confict"),
                   isPresented: showAlter,
                   presenting: confictAlterMessage)
            { _ in
                Button(String(localized: "shortcut_confict_confirm")) {
                    confictAlterMessage = ShortcutConfictAlertMessage(message: "")
                }
            } message: { message in
                Text(message.message)
            }
        }
    }
}
