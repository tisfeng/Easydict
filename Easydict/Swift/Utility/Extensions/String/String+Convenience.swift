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
            EZToast.showText("Copy Success")
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
    func trim() -> NSString {
        trimmingCharacters(in: .whitespacesAndNewlines) as NSString
    }

    func trimNewLine() -> NSString {
        trimmingCharacters(in: .newlines) as NSString
    }

    func trimToMaxLength(_ maxLength: Int) -> NSString {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > maxLength {
            return String(trimmed.prefix(maxLength)) as NSString
        }
        return trimmed as NSString
    }

    func removeInvisibleChar() -> NSString {
        replacingOccurrences(of: "\u{fffc}", with: "") as NSString
    }

    func removeExtraLineBreaks() -> NSString {
        let regex = "(\\n\\s*){2,}"
        return replacingOccurrences(
            of: regex,
            with: "\n",
            options: .regularExpression,
            range: NSRange(location: 0, length: length)
        ) as NSString
    }

    func toParagraphs() -> [String] {
        components(separatedBy: "\n")
    }

    func removeExtraLineBreaksAndToParagraphs() -> [String] {
        (removeExtraLineBreaks() as String).components(separatedBy: "\n")
    }

    func encode() -> NSString {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) as NSString? ?? self
    }

    func decode() -> NSString {
        removingPercentEncoding as NSString? ?? self
    }

    func encodeSafely() -> NSString {
        let decoded = removingPercentEncoding
        if decoded == self as String? {
            return encode()
        }
        return self
    }

    func encodeIncludingAmpersandSafely() -> NSString {
        encodeSafely(excluding: "&")
    }

    func encodeIncludingCharacters(_ includingChars: String) -> NSString {
        percentEncoded(excluding: includingChars)
    }

    func escapedXMLString() -> NSString {
        if let escaped = CFXMLCreateStringByEscapingEntities(nil, self, nil) as String? {
            return escaped as NSString
        }
        return self
    }

    func unescapedXMLString() -> NSString {
        if let unescaped = CFXMLCreateStringByUnescapingEntities(nil, self, nil) as String? {
            return unescaped as NSString
        }
        return self
    }

    func copyAndShowToast(_ showToast: Bool) {
        copyToPasteboard()
        guard length > 0, showToast else { return }
        DispatchQueue.main.async {
            EZToast.showText("Copy Success")
        }
    }

    func copyToPasteboardSafely() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [self] in
            copyToPasteboard()
        }
    }

    func isURL() -> Bool {
        detectLink() != nil
    }

    func isLink() -> Bool {
        let urlRegEx = "(?:https?://)?(?:www\\.)?\\w+\\.[a-z]+(?:/[^\\s]*)?"
        let nsRange = range(of: urlRegEx, options: .regularExpression)
        return nsRange.location != NSNotFound
    }

    func detectLink() -> NSURL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        else {
            return nil
        }
        let range = NSRange(location: 0, length: length)
        guard let result = detector.matches(in: self as String, options: [], range: range).first,
              result.resultType == .link,
              result.range.length == length
        else {
            return nil
        }
        return result.url as NSURL?
    }

    func md5() -> NSString {
        let digest = Insecure.MD5.hash(data: (self as String).data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02x", $0) }.joined() as NSString
    }

    func foldedString() -> NSString {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) as NSString
    }

    // MARK: Private helpers

    private func encodeSafely(excluding characters: String) -> NSString {
        guard let decoded = removingPercentEncoding, decoded == self as String else {
            return self
        }
        return percentEncoded(excluding: characters)
    }

    private func percentEncoded(excluding characters: String) -> NSString {
        var allowed = CharacterSet.urlQueryAllowed
        if !characters.isEmpty {
            allowed.remove(charactersIn: characters)
        }
        return addingPercentEncoding(withAllowedCharacters: allowed) as NSString? ?? self
    }
}
