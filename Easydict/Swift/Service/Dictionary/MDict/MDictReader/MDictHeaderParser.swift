//
//  MDictHeaderParser.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/02.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - Header Parsing

extension MDictReader {
    static func parseHeader(_ data: Data, cursor: inout Int) throws -> MDictHeader {
        guard data.count >= 4 else {
            throw MDictError.invalidFormat("File too small")
        }
        let headerSize = Int(readUInt32BE(data, at: cursor))
        cursor += 4

        guard cursor + headerSize + 4 <= data.count else {
            throw MDictError.invalidFormat("Header size exceeds file")
        }
        let headerBytes = data.subdata(in: cursor ..< cursor + headerSize)
        cursor += headerSize
        cursor += 4

        guard let headerText = String(data: headerBytes, encoding: .utf16LittleEndian) else {
            throw MDictError.encodingError
        }

        let version = Double(extractAttribute("GeneratedByEngineVersion", from: headerText) ?? "2.0") ?? 2.0
        let title = extractAttribute("Title", from: headerText) ?? ""
        let description = extractAttribute("Description", from: headerText) ?? ""
        let formatStr = extractAttribute("Format", from: headerText) ?? "Html"
        let caseSensitive = extractAttribute("KeyCaseSensitive", from: headerText) ?? "No"
        let encodingStr = extractAttribute("Encoding", from: headerText) ?? "utf-8"
        let encryptedStr = extractAttribute("Encrypted", from: headerText) ?? "0"
        let encrypted = Int(encryptedStr) ?? 0

        let encoding: String.Encoding
        let normalizedEncoding = encodingStr.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalizedEncoding {
        case "utf-16", "utf-16le":
            encoding = .utf16LittleEndian
        case "utf-16be":
            encoding = .utf16BigEndian
        case "gb2312", "gb18030", "gbk":
            encoding = .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            ))
        case "big5":
            encoding = .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.big5.rawValue)
            ))
        case "" where headerText.contains("<Library_Data"):
            encoding = .utf16LittleEndian
        default:
            encoding = .utf8
        }

        return MDictHeader(
            version: version,
            title: title,
            description: description,
            encoding: encoding,
            format: formatStr,
            keyCaseSensitive: caseSensitive.lowercased() == "yes",
            encrypted: encrypted
        )
    }

    static func extractAttribute(_ name: String, from text: String) -> String? {
        let pattern = "\(name)=\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                  in: text,
                  range: NSRange(text.startIndex..., in: text)
              ),
              let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[range])
    }

    static func readAttribute(_ name: String, from data: Data) -> String? {
        guard data.count >= 8 else { return nil }
        let headerSize = Int(readUInt32BE(data, at: 0))
        guard headerSize + 4 <= data.count else { return nil }
        let headerBytes = data.subdata(in: 4 ..< 4 + headerSize)
        guard let text = String(data: headerBytes, encoding: .utf16LittleEndian) else { return nil }
        return extractAttribute(name, from: text)
    }
}
