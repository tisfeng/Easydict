//
//  Dictionary+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/19.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

// MARK: - JSONCodable

// How to display a dictionary in JSON format https://alvarez.tech/swift-how-display-dictionary-json

protocol JSONCodable {
    var jsonData: Data? { get }
    func toJSONString() -> String?
}

extension JSONCodable {
    var jsonData: Data? {
        try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
    }

    /// Xcode console usage: po print(dict.toJSONString()!)
    func toJSONString() -> String? {
        if let jsonData = jsonData {
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        }
        return nil
    }
}

// MARK: - Dictionary + JSONCodable

extension Dictionary: JSONCodable {}

// MARK: - Array + JSONCodable

extension Array: JSONCodable {}
