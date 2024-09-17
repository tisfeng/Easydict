//
//  TextEditorCell.swift
//  Easydict
//
//  Created by tisfeng on 2024/5/27.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import SwiftUI

// MARK: - TextEditorCell

struct TextEditorCell: View {
    // MARK: Lifecycle

    init(
        titleKey: LocalizedStringKey,
        storedValueKey: Defaults.Key<String>,
        placeholder: LocalizedStringKey? = nil,
        alignment: TextAlignment = .leading,
        footnote: LocalizedStringKey? = nil,
        minHeight: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.titleKey = titleKey
        self.placeholder = placeholder
        self.alignment = alignment
        self.footnote = footnote
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.height = height
        _value = .init(storedValueKey)
    }

    // MARK: Internal

    let titleKey: LocalizedStringKey
    @Default var value: String
    let placeholder: LocalizedStringKey?
    var alignment: TextAlignment
    let footnote: LocalizedStringKey?
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let height: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 20) {
                Text(titleKey)

                TextEditorWithPlaceholder(text: $value, placeholder: placeholder, alignment: alignment)
                    .padding(.horizontal, 3)
                    .padding(.top, 5)
                    .padding(.bottom, 7)
                    .font(.body)
                    .lineSpacing(5)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .background(Color.clear)
                    .clipShape(corner)
                    .overlay(alignment: .center, content: {
                        corner.stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    })
                    .frame(minHeight: minHeight, maxHeight: maxHeight)
                    .frame(height: height)
            }

            if let footnote = footnote {
                Text(footnote)
                    .font(.footnote)
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
                    .textSelection(.enabled)
            }
        }
        .padding(10)
    }

    // MARK: Private

    private let corner = RoundedRectangle(cornerRadius: 5)
}

// MARK: - TextEditorWithPlaceholder

struct TextEditorWithPlaceholder: View {
    // MARK: Lifecycle

    init(
        text: Binding<String>,
        placeholder: LocalizedStringKey? = nil,
        alignment: TextAlignment = .leading
    ) {
        self._text = text
        self.placeholder = placeholder
        self.alignment = alignment
        self._placeholderAlignment = State(initialValue: alignment == .leading ? .topLeading : .topTrailing)
        self._textAlignment = State(initialValue: alignment == .leading ? .leading : .trailing)
    }

    // MARK: Internal

    @Binding var text: String
    var placeholder: LocalizedStringKey?
    var alignment: TextAlignment

    var font: Font = .body
    var lineSpacing: CGFloat = 3

    var body: some View {
        ZStack(alignment: placeholderAlignment) {
            if let placeholder, text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .lineSpacing(lineSpacing)
                    .foregroundStyle(Color(NSColor.placeholderTextColor))
                    .padding(.horizontal, 5)
                    .background(GeometryReader { geometry in
                        Color.clear.onAppear {
                            // 22 is one line height, if placeholder is more than one line, always set alignment to .leading
                            if geometry.size.height > 22 {
                                placeholderAlignment = .topLeading
                            }
                        }
                    })
            }
            TextEditor(text: $text)
                .font(font)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(textAlignment)
        }
    }

    // MARK: Private

    @State private var placeholderAlignment: Alignment = .topLeading
    @State private var textAlignment: TextAlignment = .leading
}
