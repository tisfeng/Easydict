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
    func matchingKeyBlockIndexes(for normalizedKey: String) -> [Int] {
        guard !keyBlockRanges.isEmpty else { return [] }

        var lower = 0
        var upper = keyBlockRanges.count
        while lower < upper {
            let mid = (lower + upper) / 2
            let range = keyBlockRanges[mid]
            if normalizedKey > self.normalizedKey(range.lastKey) {
                lower = mid + 1
            } else {
                upper = mid
            }
        }

        var indexes: [Int] = []
        var index = lower
        while index < keyBlockRanges.count {
            let range = keyBlockRanges[index]
            let firstKey = self.normalizedKey(range.firstKey)
            let lastKey = self.normalizedKey(range.lastKey)
            if normalizedKey < firstKey { break }
            if normalizedKey <= lastKey {
                indexes.append(index)
            }
            if normalizedKey < lastKey { break }
            index += 1
        }
        return indexes
    }

    func keyBlockIndex(containingEntry entryIndex: Int) -> Int? {
        var lower = 0
        var upper = keyBlockRanges.count

        while lower < upper {
            let mid = (lower + upper) / 2
            let range = keyBlockRanges[mid]
            if entryIndex < range.entryStartIndex {
                upper = mid
            } else if entryIndex >= range.entryEndIndex {
                lower = mid + 1
            } else {
                return mid
            }
        }
        return nil
    }

    func scannedKeyBlockIndexes(for normalizedKey: String) -> [Int] {
        keyBlockRanges.indices.filter { index in
            let range = keyBlockRanges[index]
            return normalizedKey >= self.normalizedKey(range.firstKey)
                && normalizedKey <= self.normalizedKey(range.lastKey)
        }
    }

    func matchingEntries(
        in entries: [MDictKeyEntry],
        for normalizedKey: String
    )
        -> ArraySlice<MDictKeyEntry> {
        ArraySlice(entries.filter { self.normalizedKey($0.word) == normalizedKey })
    }
}
