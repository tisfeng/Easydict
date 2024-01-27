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
    struct ShortcutSettingView: View {
        var body: some View {
            Section {
                HStack {
                    Text("input_translate")
                        .frame(minWidth: 140, alignment: .trailing)
                    GeneralKeyHolderWrapper(shortcutType: .inputTranslate).frame(width: 180, height: 24)
                }
                HStack {
                    Text("snip_translate")
                        .frame(minWidth: 140, alignment: .trailing)
                    GeneralKeyHolderWrapper(shortcutType: .snipTranslate).frame(width: 180, height: 24)
                }
                HStack {
                    Text("select_translate")
                        .frame(minWidth: 140, alignment: .trailing)
                    GeneralKeyHolderWrapper(shortcutType: .selectTranslate).frame(width: 180, height: 24)
                }
                HStack {
                    Text("show_mini_window")
                        .frame(minWidth: 140, alignment: .trailing)
                    GeneralKeyHolderWrapper(shortcutType: .showMiniWindow).frame(width: 180, height: 24)
                }
                HStack {
                    Text("silent_screenshot_ocr")
                        .frame(minWidth: 140, alignment: .trailing)
                    GeneralKeyHolderWrapper(shortcutType: .silentScreenshotOcr).frame(width: 180, height: 24)
                }
            } header: {
                Text("global_shortcut_setting")
            }
        }
    }
}
