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

struct AliWebResponse: Codable {
    struct Data: Codable {
        var translateText: String?
        var detectLanguage: String?
    }

    var requestId: String?
    var success: Bool
    var httpStatusCode: Int?
    var code: AnyCodable?
    var message: String?
    var data: Data?
}

/**
 {
   "Code" : "200",
   "Data" : {
     "Translated" : "你好",
     "WordCount" : "5"
   },
   "RequestId" : "xxxxx"
 }

 {
   "Code" : "InvalidAccessKeyId.NotFound",
   "HostId" : "mt.aliyuncs.com",
   "Message" : "Specified access key is not found.",
   "Recommend" : "https:\/\/api.aliyun.com\/troubleshoot?q=InvalidAccessKeyId.NotFound&product=alimt&requestId=xxxxx",
   "RequestId" : "xxxxx"
 }

 */
struct AliAPIResponse: Codable {
    struct Data: Codable {
        var Translated: String?
        var WordCount: String?
    }

    var Code: AnyCodable?
    var Data: Data?
    var RequestId: String?
    var Message: String?
    var HostId: String?
    var Recommend: String?
}

/**
 {
     "token": "",
     "parameterName": "",
     "headerName": ""
 }
 */

struct AliTokenResponse: Codable {
    var token: String?
    var parameterName: String?
    var headerName: String?
}

enum AnyCodable: Codable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        if let intValue = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(stringValue)
        } else {
            throw try DecodingError.dataCorruptedError(in: decoder.singleValueContainer(), debugDescription: "Code is neither Int nor String")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(stringValue):
            try container.encode(stringValue)
        case let .int(intValue):
            try container.encode(intValue)
        }
    }

    var stringValue: String? {
        switch self {
        case let .int(i):
            return String(i)
        case let .string(s):
            return s
        }
    }
}
