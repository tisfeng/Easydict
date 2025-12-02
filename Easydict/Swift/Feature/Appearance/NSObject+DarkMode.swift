//
//  NSObject+DarkMode.swift
//  Easydict
//
//  Created by Claude on 2025/1/30.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - NSObject DarkMode Extension

extension NSObject: DarkModeCapable {
    /// Check if current appearance is dark mode
    var isDarkMode: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [
            .darkAqua,
            .aqua,
        ]) == .darkAqua
    }

    /// Execute different code blocks based on current dark mode.

    /// - Parameters:
    ///   - light: Code block to execute in light mode, passes self as parameter
    ///   - dark: Code block to execute in dark mode, passes self as parameter
    ///
    /// - Important: The appropriate block will be executed one time immediately based on the current mode.
    @objc
    func executeLight(
        _ light: AnyObject? = nil,
        dark: AnyObject? = nil
    ) {
        // Create closures once
        let lightClosure = light.map { lightBlock in
            unsafeBitCast(lightBlock, to: (@convention(block) (NSObject) -> ()).self)
        }

        let darkClosure = dark.map { darkBlock in
            unsafeBitCast(darkBlock, to: (@convention(block) (NSObject) -> ()).self)
        }

        // Execute immediately based on current mode
        if isDarkMode {
            darkClosure?(self)
        } else {
            lightClosure?(self)
        }

        // Set up observer for future changes
        setupDarkModeObserver(lightHandler: {
            lightClosure?(self)
        }, darkHandler: {
            darkClosure?(self)
        })
    }
}
