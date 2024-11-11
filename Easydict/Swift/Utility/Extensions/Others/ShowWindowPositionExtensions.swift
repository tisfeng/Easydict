//
//  ShowWindowPositionExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - EZShowWindowPosition + Defaults.Serializable

extension EZShowWindowPosition: Defaults.Serializable {}

// MARK: - EZShowWindowPosition + CaseIterable

extension EZShowWindowPosition: CaseIterable {
    public static let allCases: [EZShowWindowPosition] = [.right, .mouse, .former, .center]
}

// MARK: - EZShowWindowPosition + CustomLocalizedStringResourceConvertible

extension EZShowWindowPosition: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .right:
            "fixed_window_position_right"
        case .mouse:
            "fixed_window_position_mouse"
        case .former:
            "fixed_window_position_former"
        case .center:
            "fixed_window_position_center"
        @unknown default:
            "unknown_option"
        }
    }
}
