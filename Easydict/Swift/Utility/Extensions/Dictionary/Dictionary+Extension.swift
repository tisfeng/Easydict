//
//  Dictionary+Extension.swift
//  iPoem
//
//  Created by tisfeng on 2024/8/19.
//

import Alamofire
import Foundation

extension [String: Any] {
    /// Convert dictioanry to queryString
    var queryString: String {
        var components: [(String, String)] = []

        for key in keys.sorted(by: <) {
            let value = self[key]!
            components += URLEncoding().queryComponents(fromKey: key, value: value)
        }
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
}
