//
//  AliResponse.swift
//  Easydict
//
//  Created by choykarl on 2023/12/20.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

/**
 {
     "requestId": "64AB21D8-B14C-4E53-8B78-55ACAC370F9A",
     "success": true,
     "httpStatusCode": 200,
     "code": "",
     "message": "",
     "data": {
         "translateText": "你好",
         "detectLanguage": "en"
     }
 }
 */

struct AliResponse: Codable {
    struct Data: Codable {
        var translateText: String?
        var detectLanguage: String?
    }

    var requestId: String?
    var success: Bool?
    var httpStatusCode: Int?
    var code: String?
    var message: String?
    var data: Data?
}
