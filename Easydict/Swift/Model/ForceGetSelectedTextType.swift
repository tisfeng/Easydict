//
//  ForceGetSelectedTextType.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - ForceGetSelectedTextType

@objc
enum ForceGetSelectedTextType: Int, CaseIterable, Defaults.Serializable {
    case simulatedShortcutCopy
    case menuActionCopy
}

// MARK: CustomLocalizedStringResourceConvertible

extension ForceGetSelectedTextType: CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .simulatedShortcutCopy:
            "setting.advance.force_get_selected_text_options.simulated_shortcut_copy"
        case .menuActionCopy:
            "setting.advance.force_get_selected_text_options.menu_action_copy"
        }
    }
}
