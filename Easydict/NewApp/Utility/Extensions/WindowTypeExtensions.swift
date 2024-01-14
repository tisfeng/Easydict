//
//  WindowTypeExtensions.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

extension EZWindowType: Defaults.Serializable {}

public extension EZWindowType {
    static let availableOptions: [EZWindowType] = [.mini, .fixed]
}

@available(macOS 13, *)
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
