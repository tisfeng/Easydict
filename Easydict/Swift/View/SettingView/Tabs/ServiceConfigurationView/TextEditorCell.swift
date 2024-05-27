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

            TextEditorWithPlaceholder(text: $text, placeholder: placeholder, alignment: .topTrailing)
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
                .frame(minHeight: 50, maxHeight: 200)
        }
        .padding(10)
    }

    // MARK: Private

    private let corner = RoundedRectangle(cornerRadius: 5)
}

// MARK: - TextEditorWithPlaceholder

struct TextEditorWithPlaceholder: View {
    @Binding var text: String
    let placeholder: LocalizedStringKey?
    var alignment: Alignment = .leading

    var body: some View {
        ZStack(alignment: alignment) {
            if let placeholder = placeholder, text.isEmpty {
                Text(placeholder)
                    .foregroundColor(Color(NSColor.placeholderTextColor))
                    .padding(3)
            }

            TextEditor(text: $text)
        }
    }
}
