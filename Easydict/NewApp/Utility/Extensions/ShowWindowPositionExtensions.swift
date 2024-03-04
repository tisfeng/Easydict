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

@available(macOS 13, *)
extension EZShowWindowPosition {
    public var localizedStringResource: String {
        switch self {
        case .right:
            "fixed_window_position_right".localized
        case .mouse:
            "fixed_window_position_mouse".localized
        case .former:
            "fixed_window_position_former".localized
        case .center:
            "fixed_window_position_center".localized
        @unknown default:
            "unknown_option".localized
        }
    }
}
