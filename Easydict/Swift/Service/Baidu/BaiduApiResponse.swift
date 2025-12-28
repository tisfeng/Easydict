//
//  BaiduApiResponse.swift
//  Easydict
//
//  Created by karl on 2024/7/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - BaiduApiResponse

/*
 {
     "from": "en",
     "to": "zh",
     "trans_result": [
         {
             "src": "apple",
             "dst": "苹果"
         }
     ]
 }

 */

struct BaiduApiResponse: Codable {
    // MARK: Internal

    struct TransResult: Codable {
        var src: String
        var dst: String
    }

    var from: String
    var to: String
    var transResult: [TransResult]

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case transResult = "trans_result"
        case from
        case to
    }
}

// MARK: - BaiduApiErrorResponse

/*
 {
     "error_code": "54001",
     "error_msg": "Invalid Sign"
 }
 */
struct BaiduApiErrorResponse: Codable {
    // MARK: Internal

    var errorCode: String
    var errorMsg: String

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case errorMsg = "error_msg"
    }
}
