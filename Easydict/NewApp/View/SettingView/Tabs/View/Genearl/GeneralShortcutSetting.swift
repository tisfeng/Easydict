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
                    GeneralKeyHolderWrapper().frame(width: 180, height: 24)
                }
                HStack {
                    Text("snip_translate")
                    GeneralKeyHolderWrapper().frame(width: 180, height: 24)
                }
                HStack {
                    Text("select_translate")
                    GeneralKeyHolderWrapper().frame(width: 180, height: 24)
                }
                HStack {
                    Text("silent_screenshot_ocr")
                    GeneralKeyHolderWrapper().frame(width: 180, height: 24)
                }
            } header: {
                Text("shortcut_setting")
            }
        }
    }
}
