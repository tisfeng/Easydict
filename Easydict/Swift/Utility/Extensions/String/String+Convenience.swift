//
//  String+Convenience.swift
//  Easydict
//
//  Created by tisfeng on 2025/02/17.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import CryptoKit
import Foundation

// MARK: - Swift API

extension String {
    /// Trim newline characters only.
    func trimNewLine() -> String {
        trimmingCharacters(in: .newlines)
    }

    /// Trim whitespace/newlines and cap the length.
    func trimToMaxLength(_ maxLength: Int) -> String {
        let trimmed = trim()
        if trimmed.count > maxLength {
            return String(trimmed.prefix(maxLength))
        }
        return trimmed
    }

    /// Remove invisible object replacement characters.
    func removeInvisibleChar() -> String {
        replacingOccurrences(of: "\u{fffc}", with: "")
    }

    /// Collapse multiple blank lines (and their trailing spaces) into a single newline.
    func removeExtraLineBreaks() -> String {
        replacingOccurrences(
            of: "(\\n\\s*){2,}",
            with: "\n",
            options: .regularExpression
        )
    }

    /// Split by newline only.
    func toParagraphs() -> [String] {
        components(separatedBy: "\n")
    }

    /// Remove extra line breaks, then split by newline.
    func removeExtraLineBreaksAndToParagraphs() -> [String] {
        removeExtraLineBreaks().toParagraphs()
    }

    /// Percent-encode using URLQueryAllowed.
    func encode() -> String {
        percentEncoded(excluding: "")
    }

    func decode() -> String {
        removingPercentEncoding ?? self
    }

    /// Only encode if the text is not already encoded.
    func encodeSafely() -> String {
        encodeSafely(excluding: "")
    }

    /// URL-encode including "&" safely.
    func encodeIncludingAmpersandSafely() -> String {
        encodeSafely(excluding: "&")
    }

    /// URL-encode while forcing the provided characters to be encoded.
    func encodeIncludingCharacters(_ includingChars: String) -> String {
        percentEncoded(excluding: includingChars)
    }

    /// Escape XML reserved characters.
    func escapedXMLString() -> String {
        guard let escaped = CFXMLCreateStringByEscapingEntities(
            nil,
            self as CFString,
            nil
        ) as String? else {
            return self
        }
        return escaped
    }

    func unescapedXMLString() -> String {
        guard let unescaped = CFXMLCreateStringByUnescapingEntities(
            nil,
            self as CFString,
            nil
        ) as String? else {
            return self
        }
        return unescaped
    }

    func copyAndShowToast(_ showToast: Bool) {
        copyToPasteboard()
        guard !isEmpty, showToast else {
            return
        }
        DispatchQueue.main.async {
            //            EZToast.showText("Copy Success")
        }
    }

    /// Delay copy to avoid clipboard contention with other apps.
    func copyToPasteboardSafely() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.copyToPasteboard()
        }
    }

    /// Check if the string is a valid URL (requires scheme).
    func isURL() -> Bool {
        detectLink() != nil
    }

    /// Check if the string loosely matches a link, e.g. www.google.com.
    func isLink() -> Bool {
        let pattern = "^(?:https?://)?(?:www\\.)?\\w+\\.[a-z]+(?:/[^\\s]*)?$"
        return range(of: pattern, options: .regularExpression) != nil
    }

    /// Detect a URL using NSDataDetector, ensuring the whole string is matched.
    func detectLink() -> URL? {
        guard let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        )
        else {
            return nil
        }
        let nsString = self as NSString
        let range = NSRange(location: 0, length: nsString.length)
        guard let result = detector.matches(in: self, options: [], range: range).first,
              result.resultType == .link,
              result.range.length == nsString.length
        else {
            return nil
        }
        return result.url
    }

    func md5() -> String {
        let digest = Insecure.MD5.hash(data: Data(utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func foldedString() -> String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    // MARK: Private

    private func percentEncoded(excluding characters: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        if !characters.isEmpty {
            allowed.remove(charactersIn: characters)
        }
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }

    private func encodeSafely(excluding characters: String) -> String {
        guard let decoded = removingPercentEncoding, decoded == self else {
            return self
        }
        return percentEncoded(excluding: characters)
    }
}

// MARK: - ObjC Compatibility

@objc
extension NSString {
    func ns_trim() -> NSString {
        (self as String).trim() as NSString
    }

    func ns_trimNewLine() -> NSString {
        (self as String).trimNewLine() as NSString
    }

    func ns_trimToMaxLength(_ maxLength: Int) -> NSString {
        (self as String).trimToMaxLength(maxLength) as NSString
    }

    func ns_removeInvisibleChar() -> NSString {
        (self as String).removeInvisibleChar() as NSString
    }

    func ns_removeExtraLineBreaks() -> NSString {
        (self as String).removeExtraLineBreaks() as NSString
    }

    func ns_toParagraphs() -> [String] {
        (self as String).toParagraphs()
    }

    func ns_removeExtraLineBreaksAndToParagraphs() -> [String] {
        (self as String).removeExtraLineBreaksAndToParagraphs()
    }

    func ns_encode() -> NSString {
        (self as String).encode() as NSString
    }

    func ns_decode() -> NSString {
        (self as String).decode() as NSString
    }

    func ns_encodeSafely() -> NSString {
        (self as String).encodeSafely() as NSString
    }

    func ns_encodeIncludingAmpersandSafely() -> NSString {
        (self as String).encodeIncludingAmpersandSafely() as NSString
    }

    func ns_encodeIncludingCharacters(_ includingChars: String) -> NSString {
        (self as String).encodeIncludingCharacters(includingChars) as NSString
    }

    func ns_escapedXMLString() -> NSString {
        (self as String).escapedXMLString() as NSString
    }

    func ns_unescapedXMLString() -> NSString {
        (self as String).unescapedXMLString() as NSString
    }

    func ns_copyAndShowToast(_ showToast: Bool) {
        (self as String).copyAndShowToast(showToast)
    }

    func ns_copyToPasteboardSafely() {
        (self as String).copyToPasteboardSafely()
    }

    func ns_isURL() -> Bool {
        (self as String).isURL()
    }

    func ns_isLink() -> Bool {
        (self as String).isLink()
    }

    func ns_detectLink() -> NSURL? {
        (self as String).detectLink() as NSURL?
    }

    func ns_md5() -> NSString {
        (self as String).md5() as NSString
    }

    func ns_foldedString() -> NSString {
        (self as String).foldedString() as NSString
    }
}
