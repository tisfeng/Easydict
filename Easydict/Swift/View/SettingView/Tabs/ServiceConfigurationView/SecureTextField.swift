//
//  SecureTextField.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/28.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - SecureTextField

struct SecureTextField: View {
    // MARK: Lifecycle

    init(
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        showText: Bool = false,
        recommendedText: String? = nil,
        applyContainerPadding: Bool = true,
        accessibilityLabelKey: LocalizedStringKey? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self._showText = State(initialValue: showText)
        self.recommendedText = recommendedText
        self.applyContainerPadding = applyContainerPadding
        self.accessibilityLabelKey = accessibilityLabelKey
    }

    // MARK: Internal

    @Binding var text: String
    @State var showText: Bool = false
    @State var isPreviewingRecommendation = false

    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    let recommendedText: String?
    let applyContainerPadding: Bool
    let accessibilityLabelKey: LocalizedStringKey?

    var body: some View {
        HStack {
            ZStack(alignment: .trailing) {
                SecureField(title, text: $text)
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(.trailing)
                    .focused($focus, equals: .secure)
                    .opacity(showText || isPreviewingRecommendation ? 0 : 1)
                    .disabled(isPreviewingRecommendation)
                    .accessibilityLabel(accessibilityLabel)
                TextField(title, text: $text, prompt: Text(placeholder))
                    .lineLimit(lineLimit)
                    .multilineTextAlignment(.trailing)
                    .focused($focus, equals: .text)
                    .opacity((showText || text.isEmpty) && !isPreviewingRecommendation ? 1 : 0)
                    .disabled(isPreviewingRecommendation)
                    .accessibilityLabel(accessibilityLabel)

                if isPreviewingRecommendation, let recommendedText {
                    Text(recommendedText)
                        .lineLimit(lineLimit)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                }
            }

            if showText, let recommendedText, !recommendedText.isEmpty {
                Button("service.configuration.openai.endpoint.recommend") {
                    text = recommendedText
                    isPreviewingRecommendation = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    )
                )
                .onHover { isHovering in
                    guard text != recommendedText else {
                        isPreviewingRecommendation = false
                        return
                    }
                    isPreviewingRecommendation = isHovering
                }
            }

            Button(action: {
                showText.toggle()
            }) {
                Image(systemName: showText ? "eye.slash.fill" : "eye.fill")
            }
        }
        .padding(applyContainerPadding ? 10 : 0)
        .animation(.easeInOut(duration: 0.18), value: showText)
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
            if !newValue {
                isPreviewingRecommendation = false
            }
            if focus !=
                nil { // Prevents stealing focus to this field if another field is focused, or nothing is focused
                DispatchQueue.main.async { // Needed for general iOS 16 bug with focus
                    focus = newValue ? .text : .secure
                }
            }
        }
    }

    // MARK: Private

    private enum Focus {
        case secure, text
    }

    @FocusState private var focus: Focus?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.lineLimit) private var lineLimit

    private var accessibilityLabel: Text {
        if let accessibilityLabelKey {
            return Text(accessibilityLabelKey)
        }

        return Text(title)
    }
}

// MARK: - SecureInput_Previews

struct SecureInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SecureTextField(
                title: "caiyun_translate",
                placeholder: "service.configuration.input.placeholder",
                text: .constant("1234567")
            )
            .padding()
            .previewLayout(.fixed(width: 400, height: 100))

            SecureTextField(
                title: "caiyun_translate",
                placeholder: "service.configuration.input.placeholder",
                text: .constant("")
            )
            .padding()
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 400, height: 100))
        }
    }
}
