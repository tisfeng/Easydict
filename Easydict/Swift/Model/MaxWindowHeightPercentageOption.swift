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
    case eighty = 80
    case oneHundred = 100

    var id: Int { rawValue }

    var localizedName: String {
        switch self {
        case .fifty:
            return "50%"
        case .eighty:
            return "80%"
        case .oneHundred:
            return "100%"
        }
    }

    static var defaultOption: MaxWindowHeightPercentageOption {
        .eighty
    }
}
