//
//  Data+Extension.swift
//  iPoem
//
//  Created by tisfeng on 2024/9/6.
//

import Foundation

extension Data {
    var stringValue: String? {
        String(data: self, encoding: .utf8)
    }
}
