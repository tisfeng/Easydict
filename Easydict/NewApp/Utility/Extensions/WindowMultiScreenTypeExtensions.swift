//
//  WindowMultiScreenTypeExtensions.swift
//  Easydict
//
//  Created by Sharker on 2024/3/10.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - EZShowWindowMultiScreen + Defaults.Serializable

extension EZShowWindowMultiScreen: Defaults.Serializable {}

// MARK: - EZShowWindowMultiScreen + CaseIterable

extension EZShowWindowMultiScreen: CaseIterable {
    public static let allCases: [EZShowWindowMultiScreen] = [.auto, .fixed]
}

// MARK: - EZShowWindowMultiScreen + CustomLocalizedStringResourceConvertible

@available(macOS 13, *)
extension EZShowWindowMultiScreen: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .auto:
            "show_window_multi_screen_auto"
        case .fixed:
            "show_window_multi_screen_fixed"
        @unknown default:
            "unknown_option"
        }
    }
}
