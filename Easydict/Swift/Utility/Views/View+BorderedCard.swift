//
//  View+BorderedCard.swift
//  Easydict
//
//  Created by Easydict on 2026/1/9.
//  Copyright © 2026 izual. All rights reserved.
//

import SwiftUI

// MARK: - BorderedCardModifier

/// A view modifier that applies a bordered card style with rounded corners, border, and shadow.
///
/// - Refer docs: [Reducing view modifier maintenance](https://developer.apple.com/documentation/swiftui/reducing-view-modifier-maintenance)
struct BorderedCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}

extension View {
    /// Applies a bordered card style with rounded corners, border, and subtle shadow.
    ///
    /// - Parameter cornerRadius: The corner radius for the card. Default is 6.
    ///
    /// Example:
    /// ```swift
    /// Text("Hello, World!")
    ///     .borderedCard(cornerRadius: 8)
    /// ```
    /// - Returns: A view with bordered card styling applied.
    func borderedCard(cornerRadius: CGFloat = 6) -> some View {
        modifier(BorderedCardModifier(cornerRadius: cornerRadius))
    }
}
