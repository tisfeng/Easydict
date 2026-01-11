//
//  View+DebugOnly.swift
//  Easydict
//
//  Created by Easydict on 2026/1/9.
//  Copyright © 2026 izual. All rights reserved.
//

import SwiftUI

// MARK: - DebugOnlyModifier

/// A view modifier that conditionally shows content only in debug builds.
///
/// This modifier uses `BuildConfig.isDebug` to determine whether to display the view.
/// In release builds, the view is completely hidden.
struct DebugOnlyModifier: ViewModifier {
    func body(content: Content) -> some View {
        if BuildConfig.isDebug {
            content
        }
    }
}

extension View {
    /// Shows this view only in debug builds.
    ///
    /// Use this modifier to display debug-only UI elements such as:
    /// - Development tools and controls
    /// - Debug information overlays
    /// - Testing buttons or features
    ///
    /// Example:
    /// ```swift
    /// Text("Debug Info")
    ///     .debugOnly()
    /// ```
    ///
    /// - Returns: A view that is visible only when `BuildConfig.isDebug` is true.
    func debugOnly() -> some View {
        modifier(DebugOnlyModifier())
    }
}
