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

typealias AppearanceHandler = @convention(block) (AnyObject) -> ()
typealias AppearanceChangeHandler = @convention(block) (AnyObject, Bool) -> ()

// MARK: - NSObject + DarkModeCapable

extension NSObject: DarkModeCapable {
    /// Check if current appearance is dark mode
    var isDarkMode: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [
            .darkAqua,
            .aqua,
        ]) == .darkAqua
    }

    /// Execute a single handler for the current appearance and future appearance changes.
    ///
    /// - Parameter handler: Objective-C block that receives the owner and whether the
    ///   current appearance is dark mode.
    /// - Important: Prefer this when light and dark paths share the same structure and
    ///   only differ in colors, images, or other selected values.
    @objc(executeOnAppearanceChange:)
    func executeOnAppearanceChange(_ handler: AppearanceChangeHandler? = nil) {
        executeAppearanceChange(handler: handler)
    }

    /// Execute different code blocks based on the current appearance.
    ///
    /// - Parameters:
    ///   - light: Objective-C block to execute in light mode, passing the owner
    ///   - dark: Objective-C block to execute in dark mode, passing the owner
    ///
    /// - Important: Prefer ``executeOnAppearanceChange(_:)`` for new code when light and
    ///   dark branches only differ in selected values such as colors or images.
    @objc(executeLight:dark:)
    func executeLight(
        _ light: AppearanceHandler? = nil,
        dark: AppearanceHandler? = nil
    ) {
        guard light != nil || dark != nil else {
            return
        }

        let appearanceHandler: AppearanceChangeHandler = { owner, isDarkMode in
            if isDarkMode {
                dark?(owner)
            } else {
                light?(owner)
            }
        }

        executeAppearanceChange(handler: appearanceHandler)
    }

    private func executeAppearanceChange(handler: AppearanceChangeHandler?) {
        guard let handler else {
            return
        }

        handler(self, isDarkMode)

        setupDarkModeObserver(lightHandler: { [weak self] in
            guard let self else { return }
            handler(self, false)
        }, darkHandler: { [weak self] in
            guard let self else { return }
            handler(self, true)
        })
    }
}
