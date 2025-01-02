//
//  YoudaoTranslateResponese.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/1.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - YoudaoTranslateResponse

struct YoudaoTranslateResponse: Codable {
    struct TranslateResultItem: Codable {
        let src: String
        let tgt: String
        let tgtPronounce: String?
    }

    let translateResult: [[TranslateResultItem]]
    let type: String // en2zh-CHS
    let code: Int
    let dictResult: YoudaoDictResponse?
}
