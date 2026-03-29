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

    /// Execute a single handler for the current appearance and future appearance changes.
    ///
    /// - Parameter handler: Objective-C block that receives the owner and whether the
    ///   current appearance is dark mode.
    /// - Important: Prefer this when light and dark paths share the same structure and
    ///   only differ in colors, images, or other selected values.
    @objc(ez_executeOnAppearanceChange:)
    func ez_executeOnAppearanceChange(_ handler: AnyObject? = nil) {
        let appearanceClosure = handler.map { appearanceBlock in
            unsafeBitCast(appearanceBlock, to: (@convention(block) (NSObject, Bool) -> ()).self)
        }

        guard let appearanceClosure else {
            return
        }

        appearanceClosure(self, isDarkMode)

        setupDarkModeObserver(lightHandler: { [weak self] in
            guard let self else { return }
            appearanceClosure(self, false)
        }, darkHandler: { [weak self] in
            guard let self else { return }
            appearanceClosure(self, true)
        })
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

        guard lightClosure != nil || darkClosure != nil else {
            return
        }

        let appearanceHandler: @convention(block) (NSObject, Bool) -> () = { owner, isDarkMode in
            if isDarkMode {
                darkClosure?(owner)
            } else {
                lightClosure?(owner)
            }
        }

        ez_executeOnAppearanceChange(appearanceHandler as AnyObject)
    }
}
