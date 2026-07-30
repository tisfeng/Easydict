//
//  ScreenshotTranslateDisplayMode.swift
//  Easydict
//
//  Created by bsythegreat on 2026/7/29.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - ScreenshotTranslateDisplayMode

/// Determines how screenshot translation results are presented after capture.
@objc
enum ScreenshotTranslateDisplayMode: Int, CaseIterable, Defaults.Serializable {
    case queryWindow
    case imageOverlay
    case imageSideBySide

    // MARK: Internal

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .queryWindow:
            "setting.advance.screenshot_translate_display_mode.query_window"
        case .imageOverlay:
            "setting.advance.screenshot_translate_display_mode.image_overlay"
        case .imageSideBySide:
            "setting.advance.screenshot_translate_display_mode.image_side_by_side"
        }
    }
}

// MARK: - ScreenshotOverlayDismissMode

/// Determines which input dismisses screenshot overlay and side-by-side result windows.
enum ScreenshotOverlayDismissMode: Int, CaseIterable, Defaults.Serializable {
    case escape
    case outsideClick
    case escapeOrOutsideClick

    // MARK: Internal

    var allowsEscape: Bool {
        self != .outsideClick
    }

    var allowsOutsideClick: Bool {
        self != .escape
    }

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .escape:
            "setting.advance.screenshot_overlay_dismiss_mode.escape"
        case .outsideClick:
            "setting.advance.screenshot_overlay_dismiss_mode.outside_click"
        case .escapeOrOutsideClick:
            "setting.advance.screenshot_overlay_dismiss_mode.escape_or_outside_click"
        }
    }
}
