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
    let alignment: TextAlignment
    let footnote: LocalizedStringKey?
    let minHeight: CGFloat?
    let maxHeight: CGFloat?
    let height: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 15) {
                Text(titleKey)
                textEditor
            }
            footnoteView
        }
        .padding(10)
    }

    // MARK: Private

    private var textEditor: some View {
        TextEditorWithPlaceholder(text: $value, placeholder: placeholder, alignment: alignment)
            .padding(.horizontal, 3)
            .padding(.vertical, 5)
            .font(.body)
            .lineSpacing(5)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(NSColor.separatorColor), lineWidth: 1))
            .frame(minHeight: minHeight, maxHeight: maxHeight)
            .frame(height: height)
    }

    @ViewBuilder
    private var footnoteView: some View {
        if let footnote = footnote {
            Text(footnote)
                .font(.footnote)
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
    }
}

// MARK: - TextEditorWithPlaceholder

struct TextEditorWithPlaceholder: View {
    // MARK: Lifecycle

    init(
        text: Binding<String>,
        placeholder: LocalizedStringKey? = nil,
        alignment: TextAlignment = .leading,
        font: Font = .body,
        lineSpacing: CGFloat = 3
    ) {
        self._text = text
        self.placeholder = placeholder
        self.alignment = alignment
        self.font = font
        self.lineSpacing = lineSpacing
        self._placeholderAlignment = State(initialValue: alignment == .leading ? .topLeading : .topTrailing)
        self._textAlignment = State(initialValue: alignment)
    }

    // MARK: Internal

    @Binding var text: String
    let placeholder: LocalizedStringKey?
    let alignment: TextAlignment
    let font: Font
    let lineSpacing: CGFloat

    var body: some View {
        ZStack(alignment: placeholderAlignment) {
            placeholderView
            TextEditor(text: $text)
                .font(font)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(textAlignment)
        }
        .onAppear(perform: updateAlignments)
        .onChange(of: text, perform: { _ in updateAlignments() })
    }

    // MARK: Private

    @State private var placeholderAlignment: Alignment
    @State private var textAlignment: TextAlignment

    @ViewBuilder
    private var placeholderView: some View {
        if let placeholder = placeholder, text.isEmpty {
            Text(placeholder)
                .font(font)
                .lineSpacing(lineSpacing)
                .foregroundStyle(Color(NSColor.placeholderTextColor))
                .padding(.horizontal, 5)
                .background(GeometryReader { geometry in
                    Color.clear.onAppear {
                        updatePlaceholderAlignment(height: geometry.size.height)
                    }
                })
        }
    }

    private func updateAlignments() {
        updatePlaceholderAlignment(height: 0)
        updateTextAlignment()
    }

    private func updatePlaceholderAlignment(height: CGFloat) {
        placeholderAlignment = (height > 22 || text.contains("\n")) ? .topLeading :
            (alignment == .leading ? .topLeading : .topTrailing)
    }

    private func updateTextAlignment() {
        textAlignment = text.contains("\n") ? .leading : alignment
    }
}
