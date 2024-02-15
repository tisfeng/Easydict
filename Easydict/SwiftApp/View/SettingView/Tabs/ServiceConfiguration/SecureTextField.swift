//
//  SecureTextField.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13.0, *)
struct SecureTextField: View {
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey

    @Binding var text: String?

    @State private var showText: Bool = false

    private enum Focus {
        case secure, text
    }

    @FocusState private var focus: Focus?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.lineLimit) private var lineLimit

    var body: some View {
        HStack {
            ZStack {
                SecureField(title, text: $text ?? "")
                    .lineLimit(lineLimit)
                    .focused($focus, equals: .secure)
                    .opacity(showText ? 0 : 1)
                TextField(title, text: $text ?? "", prompt: Text(placeholder))
                    .lineLimit(lineLimit)
                    .focused($focus, equals: .text)
                    .opacity(showText || (text?.isEmpty ?? true) ? 1 : 0)
            }

            Button(action: {
                showText.toggle()
            }) {
                Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
            }
        }
        .onChange(of: focus) { newValue in
            // if the PasswordField is focused externally, then make sure the correct field is actually focused
            if newValue != nil {
                focus = showText ? .text : .secure
            }
        }
        .onChange(of: scenePhase) { newValue in
            if newValue != .active {
                showText = false
            }
        }
        .onChange(of: showText) { newValue in
            if focus != nil { // Prevents stealing focus to this field if another field is focused, or nothing is focused
                DispatchQueue.main.async { // Needed for general iOS 16 bug with focus
                    focus = newValue ? .text : .secure
                }
            }
        }
    }
}

@available(macOS 13.0, *)
struct SecureInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SecureTextField(title: "caiyun_translate", placeholder: "service.configuration.input.placeholder", text: .constant("1234567"))
                .padding()
                .previewLayout(.fixed(width: 400, height: 100))

            SecureTextField(title: "caiyun_translate", placeholder: "service.configuration.input.placeholder", text: .constant(""))
                .padding()
                .preferredColorScheme(.dark)
                .previewLayout(.fixed(width: 400, height: 100))
        }
    }
}
