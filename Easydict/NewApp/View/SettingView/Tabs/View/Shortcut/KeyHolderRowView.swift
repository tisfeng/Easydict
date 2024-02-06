//
//  KeyHolderRowView.swift
//  Easydict
//
//  Created by Sharker on 2024/2/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
struct KeyHolderRowView: View {
    @State public var title: String
    @State public var type: ShortcutType
    @Binding public var confictAlterMessage: ShortcutConfictAlertMessage

    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
            Spacer()
            KeyHolderWrapper(shortcutType: type, confictAlterMessage: $confictAlterMessage).frame(width: 180, height: 24)
        }
    }
}
