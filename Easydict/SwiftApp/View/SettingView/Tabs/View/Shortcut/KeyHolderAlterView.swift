//
//  KeyHolderAlterView.swift
//  Easydict
//
//  Created by Sharker on 2024/2/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
struct KeyHolderAlterView: ViewModifier {
    init(showAlter: Binding<Bool>, confictAlterMessage: Binding<ShortcutConfictAlertMessage>) {
        _showAlter = showAlter
        _confictAlterMessage = confictAlterMessage
    }

    @Binding var showAlter: Bool
    @Binding public var confictAlterMessage: ShortcutConfictAlertMessage

    func body(content: Content) -> some View {
        content
            .alert(String(localized: "shortcut_confict \(confictAlterMessage.title)"),
                   isPresented: $showAlter,
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

@available(macOS 13, *)
public extension View {
    @ViewBuilder
    func keyHolderConfictAlter(_ showAlter: Binding<Bool>, _ confictAlterMessage: Binding<ShortcutConfictAlertMessage>) -> some View {
        modifier(KeyHolderAlterView(showAlter: showAlter, confictAlterMessage: confictAlterMessage))
    }
}
