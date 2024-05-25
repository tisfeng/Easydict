//
//  WindowTypeExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - EZWindowType + Defaults.Serializable

extension EZWindowType: Defaults.Serializable {}

extension EZWindowType {
    public static let availableOptions: [EZWindowType] = [.mini, .fixed]
}

// MARK: - EZWindowType + CustomLocalizedStringResourceConvertible

extension EZWindowType: CustomLocalizedStringResourceConvertible {
    public var localizedStringResource: LocalizedStringResource {
        switch self {
        case .fixed:
            "fixed_window"
        case .main:
            "main_window"
        case .mini:
            "mini_window"
        case .none:
            "none_window"
        @unknown default:
            "unknown_option"
        }
    }
}
