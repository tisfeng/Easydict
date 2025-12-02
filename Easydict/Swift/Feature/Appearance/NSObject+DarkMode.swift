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
        if #available(macOS 10.14, *) {
            return NSApp.effectiveAppearance.bestMatch(from: [
                .darkAqua,
                .aqua,
            ]) == .darkAqua
        }
        return false
    }

    /// Execute different code blocks based on current dark mode
    /// - Parameters:
    ///   - light: Code block to execute in light mode, passes self as parameter
    ///   - dark: Code block to execute in dark mode, passes self as parameter
    @objc
    func excuteLight(
        _ light: AnyObject? = nil,
        dark: AnyObject? = nil
    ) {
        setupDarkModeObserver(lightHandler: {
            if let lightBlock = light {
                // Cast the block to the expected signature and call it
                let lightClosure = unsafeBitCast(lightBlock, to: (@convention(block) (NSObject) -> ()).self)
                lightClosure(self)
            }
        }, darkHandler: {
            if let darkBlock = dark {
                // Cast the block to the expected signature and call it
                let darkClosure = unsafeBitCast(darkBlock, to: (@convention(block) (NSObject) -> ()).self)
                darkClosure(self)
            }
        })
    }
}
