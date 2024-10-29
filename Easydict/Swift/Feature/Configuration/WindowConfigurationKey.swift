//
//  WindowConfigurationKey.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/26.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

func windowConfigurationKey<T: _DefaultsSerializable>(
    _ key: WindowConfigurationKey,
    windowType: EZWindowType,
    defaultValue: T
)
    -> Defaults.Key<T> {
    let key = "EZConfiguration_\(key.stringValue)_Window\(windowType.rawValue)_Key"
    return .init(key, default: defaultValue)
}

// MARK: - WindowConfigurationKey

@objc
enum WindowConfigurationKey: Int {
    case inputFieldCellVisible
    case selectLanguageCellVisible

    // MARK: Internal

    var stringValue: String {
        switch self {
        case .inputFieldCellVisible: "InputFieldCellVisible"
        case .selectLanguageCellVisible: "SelectLanguageCellVisible"
        }
    }
}
