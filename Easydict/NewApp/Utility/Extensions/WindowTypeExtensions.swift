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

@available(macOS 13, *)
extension EZWindowType {
    public var localizedStringResource: String {
        switch self {
        case .fixed:
            "fixed_window".localized
        case .main:
            "main_window".localized
        case .mini:
            "mini_window".localized
        case .none:
            "none_window".localized
        @unknown default:
            "unknown_option".localized
        }
    }
}
