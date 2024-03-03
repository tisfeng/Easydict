//
//  Appearance.swift
//  Easydict
//
//  Created by yqing on 2023/12/25.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - AppearenceType

@objc
enum AppearenceType: Int, CaseIterable, Defaults.Serializable {
    case followSystem = 0
    case light
    case dark

    // MARK: Internal

    var title: String {
        switch self {
        case .followSystem:
            "appearenceType_followSystem".localized
        case .light:
            "appearenceType_light".localized
        case .dark:
            "appearenceType_dark".localized
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
        let array = AppearenceType.allCases.map(\.title)
        return array
    }
}

// MARK: - AppearenceHelper

@objcMembers
class AppearenceHelper: NSObject {
    static let shared = AppearenceHelper()

    func titles() -> [String] {
        AppearenceType.titles()
    }

    func updateAppApperance(_ apperanceType: AppearenceType) {
        NSApplication.shared.appearance = apperanceType.appearence
    }
}
