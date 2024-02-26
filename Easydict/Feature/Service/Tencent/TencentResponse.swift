//
//  TencentResponse.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

// MARK: - TencentResponse

// swiftlint:disable identifier_name
struct TencentResponse: Codable {
    struct Response: Codable {
        var RequestId: String
        var Source: String
        var Target: String
        var TargetText: String
    }

    var Response: Response
}

// MARK: - TencentErrorResponse

// swiftlint:enable identifier_name
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
    // MARK: Internal

    struct Response: Codable {
        // MARK: Internal

        var error: Error
        var requestId: String

        // MARK: Private

        // CodingKeys 枚举用于映射字段名
        private enum CodingKeys: String, CodingKey {
            case error = "Error" // error --> Error
            case requestId = "RequestId" // requestId --> RequestId
        }
    }

    struct Error: Codable {
        // MARK: Internal

        var code: String
        var message: String

        // MARK: Private

        private enum CodingKeys: String, CodingKey {
            case code = "Code" // code --> Code
            case message = "Message" // message --> Message
        }
    }

    var response: Response

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case response = "Response" // response --> Response
    }
}
