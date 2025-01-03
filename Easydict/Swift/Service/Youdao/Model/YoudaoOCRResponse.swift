//
//  YoudaoOCRResponse.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - YoudaoOCRResponse

struct YoudaoOCRResponse: Codable {
    let lanFrom: String
    let lanTo: String
    let errorCode: String
    let lines: [YoudaoOCRLine]
}

// MARK: - YoudaoOCRLine

struct YoudaoOCRLine: Codable {
    let context: String // original text
    let tranContent: String // translated text
}
