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

 error:
 {
     "requestId": "877D2097-6FE4-4B24-BAF1-41AB561C1E67",
     "success": false,
     "httpStatusCode": 500,
     "code": "ParamError",
     "message": "Query length limit exceeded",
     "data": null
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
