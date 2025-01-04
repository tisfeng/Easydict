//
//  YoudaoKey.swift
//  Easydict
//
//  Created by tisfeng on 2025/1/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - YoudaoKey

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let youdaoKey = try? JSONDecoder().decode(YoudaoKey.self, from: jsonData)

struct YoudaoKey: Codable {
    let data: DataClass
    let code: Int
    let msg: String
}

// MARK: - DataClass

struct DataClass: Codable {
    let secretKey, aesKey, aesIv: String
}

/**
 {
     "data": {
         "secretKey": "",
         "aesKey": "",
         "aesIv": ""
     },
     "code": 0,
     "msg": "OK"
 }
 */
