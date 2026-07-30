//
//  ScreenshotTranslateDisplayMode.swift
//  Easydict
//
//  Created by bsythegreat on 2026/7/29.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

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
