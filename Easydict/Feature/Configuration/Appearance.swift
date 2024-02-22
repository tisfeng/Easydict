//
//  Appearance.swift
//  Easydict
//
//  Created by yqing on 2023/12/25.
//  Copyright © 2023 izual. All rights reserved.
//

import Defaults
import Foundation

@objc enum AppearenceType: Int, CaseIterable, Defaults.Serializable {
    case followSystem = 0
    case light
    case dark

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
        let array = AppearenceType.allCases.map(\.title)
        return array
    }
}

@objcMembers class AppearenceHelper: NSObject {
    static let shared = AppearenceHelper()

    func titles() -> [String] {
        AppearenceType.titles()
    }

    func updateAppApperance(_ apperanceType: AppearenceType) {
        NSApplication.shared.appearance = apperanceType.appearence
    }
}
