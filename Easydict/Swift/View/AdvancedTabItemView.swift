//
//  AdvancedTabItemView.swift
//  Easydict
//
//  Created by Jerry on 2024-05-06.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

/// Takes in a Color, a systemImage, a text label, and an optional subtitle to quickly create a toggle or picker style for Advanced Tab in Settings.
struct AdvancedTabItemView: View {
    let color: Color
    let systemImage: String
    let labelText: LocalizedStringKey
    var subtitleText: LocalizedStringKey?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 20, height: 20, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(labelText)
                if let subtitleText {
                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        // FIXME: It seems that Toggle does not align with the AdvancedTabItemView. We need to fix this.
        .alignmentGuide(.firstTextBaseline) { context in
            if subtitleText != nil {
                context[VerticalAlignment.center]
            } else {
                context[.firstTextBaseline]
            }
        }
    }
}
