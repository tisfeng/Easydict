//
//  I18nHelper+Layout.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import WebKit

extension I18nHelper {
    /// AppKit chrome follows the interface language, not the query or translation language.
    @objc var interfaceLayoutDirection: NSUserInterfaceLayoutDirection {
        languageType.layoutDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    /// NSView does not inherit a per-view direction override, so update each native descendant.
    /// Web content keeps its own document direction; text paragraph styles are left untouched.
    @MainActor
    @objc(applyInterfaceLayoutDirectionToView:)
    func applyInterfaceLayoutDirection(to view: NSView) {
        guard !(view is WKWebView) else { return }
        if view.userInterfaceLayoutDirection != interfaceLayoutDirection {
            view.userInterfaceLayoutDirection = interfaceLayoutDirection
            view.needsUpdateConstraints = true
            view.needsLayout = true
        }
        if let menu = view.menu {
            applyInterfaceLayoutDirection(to: menu)
        }
        for subview in view.subviews {
            applyInterfaceLayoutDirection(to: subview)
        }
    }

    /// Native popup menus otherwise use the system language's direction.
    @MainActor
    func applyInterfaceLayoutDirection(to menu: NSMenu) {
        menu.userInterfaceLayoutDirection = interfaceLayoutDirection
        for item in menu.items {
            if let submenu = item.submenu {
                applyInterfaceLayoutDirection(to: submenu)
            }
        }
    }
}
