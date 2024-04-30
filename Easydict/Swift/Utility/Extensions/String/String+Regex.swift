//
//  String+Regex.swift
//  Easydict
//
//  Created by tisfeng on 2024/1/26.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension String {
    func extract(withPattern pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: utf16.count)
            if let match = regex.firstMatch(in: self, options: [], range: range) {
                if let range = Range(match.range(at: 1), in: self) {
                    return String(self[range])
                }
            }
        } catch {
            logError("Invalid regex: \(error.localizedDescription)")
        }
        return nil
    }
}
