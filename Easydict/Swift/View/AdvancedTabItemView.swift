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
    var color: Color
    var systemImage: String
    var labelText: LocalizedStringKey
    var subtitleText: LocalizedStringKey?

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 20, height: 20, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                )
            VStack(alignment: .leading) {
                Text(labelText)
                if let subtitleText {
                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
