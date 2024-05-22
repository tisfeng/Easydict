//
//  AliResponse.swift
//  Easydict
//
//  Created by choykarl on 2023/12/20.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

// MARK: - AliWebResponse

/**
 {
     "requestId": "",
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
     "requestId": "",
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

// MARK: - AliAPIResponse

/**
 {
   "Code" : "200",
   "Data" : {
     "Translated" : "你好",
     "WordCount" : "5"
   },
   "RequestId" : ""
 }

 {
   "Code" : "InvalidAccessKeyId.NotFound",
   "HostId" : "mt.aliyuncs.com",
   "Message" : "Specified access key is not found.",
   "Recommend" : "",
   "RequestId" : ""
 }

 */
struct AliAPIResponse: Codable {
    struct Data: Codable {
        enum CodingKeys: String, CodingKey {
            case translated = "Translated"
            case wordCount = "WordCount"
        }

        var translated: String?
        var wordCount: String?
    }

    enum CodingKeys: String, CodingKey {
        case data = "Data"
        case code = "Code"
        case requestId = "RequestId"
        case message = "Message"
        case hostId = "HostId"
        case recommend = "Recommend"
    }

    var code: AnyCodable?
    var data: Data?
    var requestId: String?
    var message: String?
    var hostId: String?
    var recommend: String?
}

// MARK: - AliTokenResponse

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

// MARK: - AnyCodable

enum AnyCodable: Codable {
    case string(String)
    case int(Int)

    // MARK: Lifecycle

    init(from decoder: Decoder) throws {
        if let intValue = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(stringValue)
        } else {
            throw try DecodingError.dataCorruptedError(
                in: decoder.singleValueContainer(),
                debugDescription: "Code is neither Int nor String"
            )
        }
    }

    // MARK: Internal

    var stringValue: String? {
        switch self {
        case let .int(i):
            String(i)
        case let .string(str):
            str
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
}
