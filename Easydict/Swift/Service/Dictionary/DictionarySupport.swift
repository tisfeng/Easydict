//
//  DictionarySupport.swift
//  Easydict
//
//  Created by wanzaiqidao on 2026/11/09.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - DictionarySupport

/// Shared helpers for the dictionary services that look up English headwords.
enum DictionarySupport {
    /// A single English dictionary headword: Latin letters plus the hyphen and
    /// apostrophe that `shouldQueryDictionary(maxWordCount: 1)` rejects
    /// (`well-known`, `don't`). Accented entries (`café`, `naïve`) are accepted.
    static func isSingleEnglishWord(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 60 else { return false }

        // Latin letters only: `CharacterSet.letters` would accept CJK input.
        // Folding diacritics keeps accented Latin letters while leaving CJK as-is.
        let folded = trimmed.folding(options: [.diacriticInsensitive], locale: nil)
        var allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        allowed.formUnion(.decimalDigits)
        allowed.formUnion(CharacterSet(charactersIn: "-'’"))
        guard folded.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        return folded.unicodeScalars.contains { CharacterSet.letters.contains($0) }
    }

    /// Whether a failed request was cancelled by the caller, which callers
    /// rethrow instead of reporting it as a lookup error.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }
        if let urlError = error as? URLError, urlError.code == .cancelled {
            return true
        }
        if let afError = error as? AFError, case .explicitlyCancelled = afError {
            return true
        }
        if let underlying = (error as? AFError)?.underlyingError {
            return isCancellation(underlying)
        }
        return false
    }

    /// Percent-encode a query value so reserved characters (`+`, `&`, `=`, `#`)
    /// reach the server literally instead of changing the request.
    static func percentEncodedQueryValue(_ text: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return text.addingPercentEncoding(withAllowedCharacters: allowed) ?? text
    }
}
