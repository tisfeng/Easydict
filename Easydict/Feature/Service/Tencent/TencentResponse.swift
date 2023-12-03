//
//  TencentResponse.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

struct TencentResponse: Codable {
    struct Response: Codable {
        var RequestId: String
        var Source: String
        var Target: String
        var TargetText: String
    }

    var Response: Response
}

/**
 {
   "Response": {
     "Error": {
       "Code": "InvalidParameterValue",
       "Message": "不支持的语种：hi_to_zh"
     },
     "RequestId": "eb6d17f2-6771-4653-af6f-6b2edbf07294"
   }
 }
 */
struct TencentErrorResponse: Codable {
    struct Response: Codable {
        var Error: Error
        var RequestId: String
    }

    struct Error: Codable {
        var Code: String
        var Message: String
    }

    var Response: Response
}
