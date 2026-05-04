//
//  MDictKeyIndex.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/02.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - Key Index

extension MDictReader {
    static func buildKeyIndex(
        _ entries: [MDictKeyEntry],
        caseSensitive: Bool
    )
        -> [String: [Int]] {
        var index: [String: [Int]] = [:]
        index.reserveCapacity(entries.count)
        for (i, entry) in entries.enumerated() {
            let key = caseSensitive ? entry.word : entry.word.lowercased()
            index[key, default: []].append(i)
        }
        return index
    }
}
