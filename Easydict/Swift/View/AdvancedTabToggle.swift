//
//  AdvancedTabToggle.swift
//  Easydict
//
//  Created by Jerry on 2024-05-06.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

/// Takes in a Color, String, and LocalizedStringKey to create a toggle for Advanced Tab in Settings.
struct AdvancedTabToggle: View {
    var color: Color
    var systemImage: String
    var labelText: LocalizedStringKey

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(width: 20, height: 20, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                )
            Text(labelText)
        }
    }
}
