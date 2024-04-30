// swiftlint:disable all
//
//  CaiyunResponse.swift
//  Easydict
//
//  Created by Kyle on 2023/11/24.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

struct CaiyunResponse: Codable {
    var confidence: Double
    var rc: Int
    var target: [String]
}

// swiftlint:enable all
