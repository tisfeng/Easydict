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

    func matchingEntries(
        in entries: [MDictKeyEntry],
        for normalizedKey: String
    )
        -> ArraySlice<MDictKeyEntry> {
        guard !entries.isEmpty else { return [] }

        let start = lowerBound(in: entries, for: normalizedKey)
        guard start < entries.count,
              self.normalizedKey(entries[start].word) == normalizedKey
        else { return [] }

        let end = upperBound(in: entries, for: normalizedKey, startingAt: start)
        return entries[start ..< end]
    }

    private func lowerBound(
        in entries: [MDictKeyEntry],
        for normalizedKey: String
    )
        -> Int {
        var lower = 0
        var upper = entries.count
        while lower < upper {
            let mid = (lower + upper) / 2
            if self.normalizedKey(entries[mid].word) < normalizedKey {
                lower = mid + 1
            } else {
                upper = mid
            }
        }
        return lower
    }

    private func upperBound(
        in entries: [MDictKeyEntry],
        for normalizedKey: String,
        startingAt start: Int
    )
        -> Int {
        var lower = start
        var upper = entries.count
        while lower < upper {
            let mid = (lower + upper) / 2
            if self.normalizedKey(entries[mid].word) <= normalizedKey {
                lower = mid + 1
            } else {
                upper = mid
            }
        }
        return lower
    }
}
