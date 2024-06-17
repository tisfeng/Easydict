//
//  TextEditorCell.swift
//  Easydict
//
//  Created by tisfeng on 2024/5/27.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// MARK: - TextEditorCell

struct TextEditorCell: View {
    // MARK: Internal

    let title: LocalizedStringKey
    @Binding var text: String
    let placeholder: LocalizedStringKey

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(title)

            TrailingTextEditorWithPlaceholder(text: $text, placeholder: placeholder)
                .padding(.horizontal, 3)
                .padding(.top, 5)
                .padding(.bottom, 7)
                .font(.body)
                .lineSpacing(5)
                .scrollContentBackground(.hidden) // Refer https://stackoverflow.com/a/62848618/8378840
                .scrollIndicators(.hidden)
                .background(Color.clear)
                .clipShape(corner)
                .overlay(alignment: .center, content: {
                    corner.stroke(Color(NSColor.separatorColor), lineWidth: 1)
                })
                .frame(minHeight: 55, maxHeight: 200) // min height is two lines, for English placeholder.
        }
        .padding(10)
    }

    // MARK: Private

    private let corner = RoundedRectangle(cornerRadius: 5)
}

// MARK: - TrailingTextEditorWithPlaceholder

struct TrailingTextEditorWithPlaceholder: View {
    @Binding var text: String
    let placeholder: LocalizedStringKey?
    @State var oneLineAlignment: Alignment = .topTrailing

    var body: some View {
        ZStack(alignment: oneLineAlignment) {
            if let placeholder = placeholder, text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(Color(NSColor.placeholderTextColor))
                    .padding(.horizontal, 5)
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear {
                            // 22 is one line height, if placeholder is more than one line, alway set alignment to .leading
                            if geometry.size.height > 22 {
                                oneLineAlignment = .topLeading
                            }
                        }
                    })
            }

            TextEditor(text: $text)
                .multilineTextAlignment(.trailing)
                .onChange(of: text) { newValue in
                    print("TextEditor onChange: \(text)")
                    print("newValue: \(newValue)")
                }
        }
    }
}
