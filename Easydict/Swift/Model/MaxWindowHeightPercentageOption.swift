//
//  MaxWindowHeightPercentageOption.swift
//  Easydict
//
//  Created by AI Agent on 2024-03-07. // Updated
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

enum MaxWindowHeightPercentageOption: Int, CaseIterable, Identifiable {
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
