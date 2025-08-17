//
//  Encodable+JSON.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/19.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - Encodable + toJSONString

extension Encodable {
    func toJSONString(outputFormatting: JSONEncoder.OutputFormatting = .init()) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    /// Print pretty JSON string. `NSString` allows you to pretty print newline instead of `\n`, https://stackoverflow.com/a/68760531/8378840
    var prettyJSONString: NSString {
        if let jsonString = toJSONString(outputFormatting: .customized) {
            return jsonString as NSString
        }
        return "{}" as NSString
    }

    var jsonData: Data? {
        try? JSONEncoder().encode(self)
    }

    var jsonString: String? {
        if let jsonData {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
}

// Extension for formatting JSON output
extension JSONEncoder.OutputFormatting {
    static let customized: JSONEncoder.OutputFormatting = [
        .prettyPrinted,
        .sortedKeys,
        .withoutEscapingSlashes,
    ]
}
