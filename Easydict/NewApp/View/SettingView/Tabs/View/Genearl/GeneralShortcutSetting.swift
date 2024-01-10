//
//  GeneralShortcutSetting.swift
//  Easydict
//
//  Created by Sharker on 2024/1/1.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
extension GeneralTab {
    struct ShortcutSettingView: View {
        var body: some View {
            Section {
                HStack {
                    Text("input_translate")
                    GeneralKeyHolderWrapper()
                }
                HStack {
                    Text("snip_translate")
                    GeneralKeyHolderWrapper()
                }
                HStack {
                    Text("select_translate")
                    GeneralKeyHolderWrapper()
                }
                HStack {
                    Text("silent_screenshot_ocr")
                    GeneralKeyHolderWrapper()
                }
            } header: {
                Text("shortcut_setting")
            }
        }
    }
}
