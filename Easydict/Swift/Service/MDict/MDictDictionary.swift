//
//  MDictDictionary.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - MDictDictionary

/// A loaded MDict dictionary backed by one MDX file and optional MDD resource files.
///
/// Provides word lookup returning raw HTML/text definitions, and resource resolution
/// for multimedia links found inside MDX definitions.
final class MDictDictionary {
    // MARK: Lifecycle

    init(mdxURL: URL, mddURLs: [URL] = []) throws {
        self.mdxURL = mdxURL
        self.mdxReader = try MDictReader(url: mdxURL)
        self.mddReaders = try mddURLs.map { try MDictReader(url: $0) }
        self.title = mdxReader.header.title.isEmpty
            ? mdxURL.deletingPathExtension().lastPathComponent
            : mdxReader.header.title
        self.isHTML = mdxReader.header.isHTML
    }

    // MARK: Internal

    let mdxURL: URL
    let title: String
    let isHTML: Bool

    var description: String { mdxReader.header.description }

    // MARK: - Lookup

    /// Returns the definition HTML/text for a word, or `nil` if not found.
    func lookup(_ word: String) throws -> String? {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var definitions = try mdxReader.lookupAll(trimmed)

        if definitions.isEmpty, !mdxReader.header.keyCaseSensitive {
            definitions = try mdxReader.lookupAll(trimmed.lowercased())
            if definitions.isEmpty {
                definitions = try mdxReader.lookupAll(trimmed.capitalized)
            }
        }

        guard !definitions.isEmpty else { return nil }
        let raw = definitions.joined(separator: "\n")

        if isHTML {
            return resolveLinks(in: raw)
        }
        return raw
    }

    /// Returns raw binary data for a resource key (used by MDD files).
    func lookupResource(_ key: String) throws -> Data? {
        let candidates = resourceKeyCandidates(for: key)
        for reader in mddReaders {
            for candidate in candidates {
                if let data = try reader.lookupData(for: candidate) {
                    return data
                }
            }
        }
        return nil
    }

    // MARK: Private

    private let mdxReader: MDictReader
    private let mddReaders: [MDictReader]

    private func resourceKeyCandidates(for key: String) -> [String] {
        let decoded = (key.removingPercentEncoding ?? key)
            .components(separatedBy: CharacterSet(charactersIn: "?#"))
            .first ?? key
        let normalized = decoded.replacingOccurrences(of: "/", with: "\\")
        let withoutSlash = normalized.hasPrefix("\\")
            ? String(normalized.dropFirst())
            : normalized
        let withSlash = normalized.hasPrefix("\\") ? normalized : "\\\(normalized)"
        var seen = Set<String>()
        return [normalized, withSlash, withoutSlash].filter { seen.insert($0).inserted }
    }

    /// Rewrites MDict links so WebKit can render local resources without a scheme handler.
    private func resolveLinks(in html: String) -> String {
        var result = html
        result = result.replacingOccurrences(
            of: "entry://",
            with: "mdict-entry://"
        )
        result = replaceSoundLinks(in: result)
        result = replaceStylesheetLinks(in: result)
        result = replaceResourceAttributes(in: result)
        result = replaceSourceSets(in: result)
        result = replaceCSSResources(in: result)
        result = replaceAudioConstructors(in: result)
        return result
    }

    private func replaceSoundLinks(in html: String) -> String {
        replaceMatches(
            in: html,
            pattern: "(?i)sound://([^\"'\\s)<>]+)"
        ) { match, source in
            guard let keyRange = Range(match.range(at: 1), in: source) else { return nil }
            return dataURI(for: String(source[keyRange]))
        }
    }

    private func replaceResourceAttributes(in html: String) -> String {
        replaceMatches(
            in: html,
            pattern: "(?i)((?:src|poster)\\s*=\\s*[\"'])([^\"']+)([\"'])"
        ) { match, source in
            guard let prefixRange = Range(match.range(at: 1), in: source),
                  let keyRange = Range(match.range(at: 2), in: source),
                  let suffixRange = Range(match.range(at: 3), in: source)
            else { return nil }

            let key = String(source[keyRange])
            guard shouldResolveResource(key),
                  let dataURI = dataURI(for: key)
            else { return nil }

            return "\(source[prefixRange])\(dataURI)\(source[suffixRange])"
        }
    }

    private func replaceSourceSets(in html: String) -> String {
        replaceMatches(
            in: html,
            pattern: "(?i)(srcset\\s*=\\s*[\"'])([^\"']+)([\"'])"
        ) { match, source in
            guard let prefixRange = Range(match.range(at: 1), in: source),
                  let valueRange = Range(match.range(at: 2), in: source),
                  let suffixRange = Range(match.range(at: 3), in: source)
            else { return nil }

            let rewritten = source[valueRange]
                .split(separator: ",")
                .map { candidate -> String in
                    let parts = candidate.split(separator: " ", omittingEmptySubsequences: true)
                    guard let key = parts.first,
                          shouldResolveResource(String(key)),
                          let dataURI = dataURI(for: String(key))
                    else { return String(candidate) }

                    let descriptor = parts.dropFirst().joined(separator: " ")
                    return descriptor.isEmpty ? dataURI : "\(dataURI) \(descriptor)"
                }
                .joined(separator: ", ")
            return "\(source[prefixRange])\(rewritten)\(source[suffixRange])"
        }
    }

    private func replaceStylesheetLinks(in html: String) -> String {
        replaceMatches(
            in: html,
            pattern: "(?is)<link\\b(?=[^>]*\\brel\\s*=\\s*[\"']?stylesheet[\"']?)[^>]*\\bhref\\s*=\\s*[\"']([^\"']+)[\"'][^>]*>"
        ) { match, source in
            guard let keyRange = Range(match.range(at: 1), in: source) else { return nil }
            let key = String(source[keyRange])
            guard shouldResolveResource(key),
                  let css = stylesheetText(for: key)
            else { return nil }

            return "<style>\(css)</style>"
        }
    }

    private func replaceCSSResources(in html: String) -> String {
        replaceMatches(
            in: html,
            pattern: "(?i)(url\\([\"']?)([^\"')]+)([\"']?\\))"
        ) { match, source in
            guard let prefixRange = Range(match.range(at: 1), in: source),
                  let keyRange = Range(match.range(at: 2), in: source),
                  let suffixRange = Range(match.range(at: 3), in: source)
            else { return nil }

            let key = String(source[keyRange])
            guard shouldResolveResource(key),
                  let dataURI = dataURI(for: key)
            else { return nil }

            return "\(source[prefixRange])\(dataURI)\(source[suffixRange])"
        }
    }

    private func replaceAudioConstructors(in html: String) -> String {
        replaceMatches(
            in: html,
            pattern: "(?i)new\\s+Audio\\((.*?)\\)"
        ) { match, source in
            guard let argumentRange = Range(match.range(at: 1), in: source) else { return nil }
            let rawArgument = String(source[argumentRange])
            let key = rawArgument
                .replacingOccurrences(of: "&quot;", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
            guard shouldResolveResource(key),
                  let dataURI = dataURI(for: key)
            else { return nil }

            return "new Audio('\(dataURI)')"
        }
    }

    private func replaceMatches(
        in html: String,
        pattern: String,
        replacement: (NSTextCheckingResult, String) -> String?
    )
        -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return html }

        var result = html
        let matches = regex.matches(
            in: result,
            range: NSRange(result.startIndex..., in: result)
        )
        for match in matches.reversed() {
            guard let fullRange = Range(match.range, in: result),
                  let replacementText = replacement(match, result)
            else { continue }
            result.replaceSubrange(fullRange, with: replacementText)
        }
        return result
    }

    private func shouldResolveResource(_ key: String) -> Bool {
        let lowercased = key.lowercased()
        return !lowercased.hasPrefix("data:")
            && !lowercased.hasPrefix("http://")
            && !lowercased.hasPrefix("https://")
            && !lowercased.hasPrefix("file:")
            && !lowercased.hasPrefix("about:")
            && !lowercased.hasPrefix("#")
            && !lowercased.hasPrefix("mdict-entry://")
            && !lowercased.hasPrefix("x-dictionary:")
    }

    private func dataURI(for key: String) -> String? {
        guard let data = try? lookupResource(key), !data.isEmpty else { return nil }
        return "data:\(mimeType(for: key));base64,\(data.base64EncodedString())"
    }

    private func stylesheetText(for key: String) -> String? {
        guard let data = try? lookupResource(key), !data.isEmpty else { return nil }
        let css = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .utf16LittleEndian)
            ?? String(data: data, encoding: .utf16BigEndian)
        return css.map { replaceCSSResources(in: $0) }
    }

    private func mimeType(for key: String) -> String {
        let path = (key.removingPercentEncoding ?? key)
            .components(separatedBy: CharacterSet(charactersIn: "?#"))
            .first ?? key
        switch URL(fileURLWithPath: path).pathExtension.lowercased() {
        case "apng":
            return "image/apng"
        case "avif":
            return "image/avif"
        case "gif":
            return "image/gif"
        case "jpeg", "jpg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "svg":
            return "image/svg+xml"
        case "webp":
            return "image/webp"
        case "aac":
            return "audio/aac"
        case "m4a":
            return "audio/mp4"
        case "mp3":
            return "audio/mpeg"
        case "oga", "ogg":
            return "audio/ogg"
        case "wav":
            return "audio/wav"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: Equatable

extension MDictDictionary: Equatable {
    static func == (lhs: MDictDictionary, rhs: MDictDictionary) -> Bool {
        lhs.mdxURL == rhs.mdxURL
    }
}

// MARK: Identifiable

extension MDictDictionary: Identifiable {
    var id: URL { mdxURL }
}
