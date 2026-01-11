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
enum AppearanceType: Int, CaseIterable, Defaults.Serializable, CustomStringConvertible {
    case followSystem = 0
    case light
    case dark

    // MARK: Internal

    var title: String {
        switch self {
        case .followSystem:
            NSLocalizedString("appearanceType_followSystem", comment: "")
        case .light:
            NSLocalizedString("appearanceType_light", comment: "")
        case .dark:
            NSLocalizedString("appearanceType_dark", comment: "")
        }
    }

    var appearance: NSAppearance? {
        switch self {
        case .followSystem:
            nil
        case .light:
            NSAppearance(named: .aqua)
        case .dark:
            NSAppearance(named: .darkAqua)
        }
    }

    // MARK: CustomStringConvertible

    var description: String {
        title
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
        NSApplication.shared.appearance = apperanceType.appearance
    }
}
