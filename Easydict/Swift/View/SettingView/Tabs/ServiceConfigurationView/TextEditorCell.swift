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
    let title: LocalizedStringKey
    @Binding var text: String

    let corner = RoundedRectangle(cornerRadius: 5)

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            Text(title)
            TextEditor(text: $text)
                .padding(.horizontal, 3)
                .padding(.vertical, 5)
                .font(.body)
                .lineSpacing(5)
                .scrollContentBackground(.hidden)
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
}
