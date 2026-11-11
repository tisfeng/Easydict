//
//  SheetChevronRow.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import SFSafeSymbols
import SwiftUI

/// Opens settings in a sheet from a full-width, keyboard-accessible navigation row.
struct SheetChevronRow<Label: View, Content: View>: View {
    // MARK: Internal

    @ViewBuilder var label: () -> Label
    @ViewBuilder var content: () -> Content

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                label()
                Image(systemSymbol: .chevronRight)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            content()
        }
    }

    // MARK: Private

    @State private var isPresented = false
}
