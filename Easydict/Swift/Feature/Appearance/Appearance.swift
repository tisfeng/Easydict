//
//  Appearance.swift
//  Easydict
//
//  Created by yqing on 2023/12/25.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - AppearanceType

@objc
enum AppearanceType: Int, CaseIterable, Defaults.Serializable {
    case followSystem = 0
    case light
    case dark

    // MARK: Internal

    var title: String {
        switch self {
        case .followSystem:
            NSLocalizedString("appearenceType_followSystem", comment: "")
        case .light:
            NSLocalizedString("appearenceType_light", comment: "")
        case .dark:
            NSLocalizedString("appearenceType_dark", comment: "")
        }
    }

    var appearence: NSAppearance? {
        switch self {
        case .followSystem:
            nil
        case .light:
            NSAppearance(named: .aqua)
        case .dark:
            NSAppearance(named: .darkAqua)
        }
    }

    static func titles() -> [String] {
        let array = AppearanceType.allCases.map(\.title)
        return array
    }
}

// MARK: - AppearanceHelper

@objcMembers
class AppearanceHelper: NSObject {
    static let shared = AppearanceHelper()

    func titles() -> [String] {
        AppearanceType.titles()
    }

    func updateAppAppearance(_ apperanceType: AppearanceType) {
        NSApplication.shared.appearance = apperanceType.appearence
    }
}
