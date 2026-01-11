//
//  View+Builder.swift
//  Easydict
//
//  Created by tisfeng on 2024/12/1.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - ViewModifier

extension View {
    @ViewBuilder
    func disableWindowMinimize() -> some View {
        if #available(macOS 15.0, *) {
            windowMinimizeBehavior(.disabled)
        } else {
            self
        }
    }

    @ViewBuilder
    func hideWindowToolbarBackground() -> some View {
        if #available(macOS 15.0, *) {
            toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } else {
            self
        }
    }

    @ViewBuilder
    func thickMaterialWindowBackground() -> some View {
        if #available(macOS 15.0, *) {
            containerBackground(.thickMaterial, for: .window)
        } else {
            self
        }
    }
}
