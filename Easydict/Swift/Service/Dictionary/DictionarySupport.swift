//
//  DictionarySupport.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/09.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - DictionarySupport

/// Shared helpers for the dictionary services that look up English headwords.
enum DictionarySupport {
    /// A single English dictionary headword: Latin letters plus the hyphen and
    /// apostrophe that `shouldQueryDictionary(maxWordCount: 1)` rejects
    /// (`well-known`, `don't`).
    static func isSingleEnglishWord(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 60 else { return false }

        // Latin letters only: `CharacterSet.letters` would accept CJK input.
        var allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        allowed.formUnion(.decimalDigits)
        allowed.formUnion(CharacterSet(charactersIn: "-'’"))
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        return trimmed.unicodeScalars.contains { CharacterSet.letters.contains($0) }
    }

    /// Percent-encode a query value so reserved characters (`+`, `&`, `=`, `#`)
    /// reach the server literally instead of changing the request.
    static func percentEncodedQueryValue(_ text: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }
}
