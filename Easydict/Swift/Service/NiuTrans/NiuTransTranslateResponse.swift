//
//  NiuTransTranslateResponse.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - NiuTransTranslateResponse

/// NiuTrans Translate Response
///
/// Docs: https://niutrans.com/documents/contents/trans_text#languageList
///
/// Success response:
/// ```json
/// {
///     "from": "zh",
///     "to": "en",
///     "tgt_text": "Hello"
/// }
/// ```
///
/// Failure response:
/// ```json
/// {
///     "apikey": "",
///     "error_code": "13002",
///     "error_msg": "apikey is empty",
///     "from": "en",
///     "src_text": "good",
///     "to": "zh"
/// }
/// ```
struct NiuTransTranslateResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case from
        case to
        case tgtText = "tgt_text"
        case srcText = "src_text"
        case errorMsg = "error_msg"
        case errorCode = "error_code"
        case apikey
    }

    let from: String?
    let to: String?
    let tgtText: String?
    let srcText: String?
    let errorMsg: String?
    let errorCode: String?
    let apikey: String?
}
