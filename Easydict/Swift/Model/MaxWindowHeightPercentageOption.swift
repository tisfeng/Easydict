//
//  MaxWindowHeightPercentageOption.swift
//  Easydict
//
//  Created by AI Agent on 2025-06-19.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

enum MaxWindowHeightPercentageOption: Int, CaseIterable, Identifiable {
    case twenty = 20
    case thirty = 30
    case forty = 40
    case fifty = 50
    case sixty = 60
    case seventy = 70
    case eighty = 80
    case ninety = 90
    case oneHundred = 100

    // MARK: Internal

    static var defaultOption: MaxWindowHeightPercentageOption {
        .oneHundred
    }

    var id: Int { rawValue }

    var title: String {
        "\(rawValue)%"
    }
}
