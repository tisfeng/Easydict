//
//  MDictDictionary.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

private let maxMDictCachedDataURIBytes = 32 * 1024 * 1024
private let maxMDictCachedSingleDataURIBytes = 8 * 1024 * 1024
private let maxMDictResolvedDataURIBytesPerLookup = 1536 * 1024
private let maxMDictResolvedDataURICountPerLookup = 96
private let maxMDictCachedCSSBytes = 4 * 1024 * 1024
private let maxMDictCachedCSSEntryBytes = 2 * 1024 * 1024
private let maxMDictMissingResourceCount = 512
private let maxMDictSearchIndexEntryCount = 200_000
private let maxMDictLinkResolutionDepth = 8

// MARK: - MDictDictionary

/// A loaded MDict dictionary backed by one MDX file and optional MDD resource files.
///
/// Provides word lookup returning raw HTML/text definitions, and resource resolution
/// for multimedia links found inside MDX definitions.
final class MDictDictionary: @unchecked Sendable {
    // MARK: Lifecycle

    init(mdxURL: URL, mddURLs: [URL] = []) throws {
        self.mdxURL = mdxURL
        self.mdxReader = try MDictReader(url: mdxURL)
        self.mddURLs = mddURLs
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

    static func decodeResourceText(_ data: Data, preferredEncoding: String.Encoding) -> String? {
        let encodings: [String.Encoding] = [
            preferredEncoding,
            .utf8,
            .utf16LittleEndian,
            .utf16BigEndian,
        ]
        var seen = Set<UInt>()
        for encoding in encodings where seen.insert(encoding.rawValue).inserted {
            guard var text = String(data: data, encoding: encoding) else { continue }
            if text.hasPrefix("\u{FEFF}") {
                text.removeFirst()
            }
            return text
        }
        return nil
    }

    static func linkedKeyword(in definition: String) -> String? {
        let prefix = "@@@LINK="
        let trimmed = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { return nil }

        let keyword = trimmed.dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return keyword.isEmpty ? nil : keyword
    }

    // MARK: - Lookup

    /// Returns the definition HTML/text for a word, or `nil` if not found.
    func lookup(_ word: String) throws -> String? {
        lookupLock.lock()
        defer { lookupLock.unlock() }

        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let definitions = try lookupDefinitions(for: trimmed)

        guard !definitions.isEmpty else { return nil }
        let raw = definitions.joined(separator: "\n")

        if isHTML {
            return resolveLinks(in: raw)
        }
        return raw
    }

    /// Returns raw binary data for a resource key (used by MDD files).
    func lookupResource(_ key: String) throws -> Data? {
        lookupLock.lock()
        defer { lookupLock.unlock() }

        let candidates = resourceKeyCandidates(for: key)
        for reader in loadedMDDReaders() {
            for candidate in candidates {
                if let data = try reader.lookupData(for: candidate) {
                    return data
                }
            }
        }
        return nil
    }

    // MARK: Private

    private static let soundLinkRegex = makeRegex(
        "(?i)(?<![A-Za-z0-9_-])(?:mdict-sound|sound)://([^\"'\\s)<>]+)"
    )
    private static let resourceAttributeRegex = makeRegex("(?i)((?:src|poster)\\s*=\\s*[\"'])([^\"']+)([\"'])")
    private static let sourceSetRegex = makeRegex("(?i)(srcset\\s*=\\s*[\"'])([^\"']+)([\"'])")
    private static let stylesheetLinkRegex = makeRegex(
        "(?is)<link\\b(?=[^>]*\\brel\\s*=\\s*[\"']?stylesheet[\"']?)[^>]*\\bhref\\s*=\\s*[\"']([^\"']+)[\"'][^>]*>"
    )
    private static let scriptLinkRegex = makeRegex(
        "(?is)<script\\b([^>]*?)\\bsrc\\s*=\\s*[\"']([^\"']+)[\"']([^>]*)>\\s*</script>"
    )
    private static let nonceAttributeRegex = makeRegex(
        "(?i)\\s*\\bnonce\\s*=\\s*([\"'])[^\"']*\\1"
    )
    private static let cssURLRegex = makeRegex("(?i)(url\\([\"']?)([^\"')]+)([\"']?\\))")
    private static let audioConstructorRegex = makeRegex("(?i)new\\s+Audio\\((.*?)\\)")

    private let mdxReader: MDictReader
    private let mddURLs: [URL]
    private let lookupLock = NSRecursiveLock()
    private var cachedMDDReaders: [MDictReader]?
    private var cachedDataURIs: [String: String] = [:]
    private var dataURICacheOrder: [String] = []
    private var dataURICacheBytes = 0
    private var cachedStylesheets: [String: String] = [:]
    private var stylesheetCacheOrder: [String] = []
    private var stylesheetCacheBytes = 0
    private var missingResourceKeys = Set<String>()
    private var missingResourceOrder: [String] = []
    private var searchIndex: MDictSearchIndex?
    private var resolvedDataURIBytes = 0
    private var resolvedDataURICount = 0
    private var dataURIBudgetMissCount = 0
    private var cachedLocalStylesheet: String?
    private var didLoadLocalStylesheet = false

    private static func javaScriptStringLiteral(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\u{2028}", with: "\\u2028")
            .replacingOccurrences(of: "\u{2029}", with: "\\u2029")
        return "'\(escaped)'"
    }

    private static func makeRegex(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid MDict regex: \(pattern)")
        }
    }

    private static func escapeInlineScript(_ script: String) -> String {
        script.replacingOccurrences(
            of: "</script",
            with: "<\\/script",
            options: .caseInsensitive
        )
    }

    private static func preservedScriptAttributes(_ raw: String) -> String {
        let range = NSRange(raw.startIndex..., in: raw)
        let stripped = nonceAttributeRegex.stringByReplacingMatches(
            in: raw,
            range: range,
            withTemplate: ""
        )
        let trimmed = stripped.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : " \(trimmed)"
    }

    private func loadedMDDReaders() -> [MDictReader] {
        if let cachedMDDReaders {
            return cachedMDDReaders
        }

        let readers = mddURLs.compactMap { url in
            do {
                return try MDictReader(url: url)
            } catch {
                logError("MDictDictionary: failed to load MDD \(url.path): \(error)")
                return nil
            }
        }
        cachedMDDReaders = readers
        return readers
    }

    private func lookupDefinitions(for word: String) throws -> [String] {
        try lookupDefinitions(for: word, visitedWords: [], depth: 0)
    }

    private func lookupDefinitions(
        for word: String,
        visitedWords: Set<String>,
        depth: Int
    ) throws
        -> [String] {
        let definitions = try directLookupDefinitions(for: word)
        guard definitions.count == 1,
              let linkedKeyword = Self.linkedKeyword(in: definitions[0]),
              depth < maxMDictLinkResolutionDepth
        else { return definitions }

        let normalizedWord = mdxReader.normalizedKey(word)
        let normalizedLinkedKeyword = mdxReader.normalizedKey(linkedKeyword)
        guard normalizedWord != normalizedLinkedKeyword,
              !visitedWords.contains(normalizedLinkedKeyword)
        else { return definitions }

        var nextVisitedWords = visitedWords
        nextVisitedWords.insert(normalizedWord)
        let linkedDefinitions = try lookupDefinitions(
            for: linkedKeyword,
            visitedWords: nextVisitedWords,
            depth: depth + 1
        )
        return linkedDefinitions.isEmpty ? definitions : linkedDefinitions
    }

    private func directLookupDefinitions(for word: String) throws -> [String] {
        var definitions = try mdxReader.lookupAll(word)

        if definitions.isEmpty, !mdxReader.header.keyCaseSensitive {
            definitions = try mdxReader.lookupAll(word.lowercased())
            if definitions.isEmpty {
                definitions = try mdxReader.lookupAll(word.capitalized)
            }
        }
        if !definitions.isEmpty { return definitions }

        for candidate in MDictInflection.candidates(for: word) {
            definitions = try mdxReader.lookupAll(candidate)
            if !definitions.isEmpty { return definitions }
        }

        for candidate in try fallbackSearchCandidates(for: word) {
            definitions = try mdxReader.lookupAll(candidate)
            if !definitions.isEmpty { return definitions }
        }
        return []
    }

    private func fallbackSearchCandidates(for word: String) throws -> [String] {
        guard mdxReader.entryCount <= maxMDictSearchIndexEntryCount else {
            return []
        }
        if searchIndex == nil {
            searchIndex = try MDictSearchIndex(
                entries: mdxReader.allKeyEntries(),
                caseSensitive: mdxReader.header.keyCaseSensitive
            )
        }
        return searchIndex?.candidates(for: word) ?? []
    }

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
        return [decoded, normalized, withSlash, withoutSlash].filter { seen.insert($0).inserted }
    }

    private func dataURI(for key: String) -> String? {
        let cacheKey = resourceCacheKey(for: key)
        if let cached = cachedDataURIs[cacheKey] {
            guard reserveDataURIBudget(bytes: cached.utf8.count) else {
                dataURIBudgetMissCount += 1
                return nil
            }
            markDataURICacheHit(cacheKey)
            return cached
        }
        guard !missingResourceKeys.contains(cacheKey),
              let data = try? lookupResource(key),
              !data.isEmpty
        else {
            markMissingResource(cacheKey)
            return nil
        }

        let mimeType = mimeType(for: key)
        let bytes = dataURIByteCount(dataByteCount: data.count, mimeType: mimeType)
        guard reserveDataURIBudget(bytes: bytes) else {
            dataURIBudgetMissCount += 1
            return nil
        }

        let dataURI = "data:\(mimeType);base64,\(data.base64EncodedString())"
        cacheDataURI(dataURI, for: cacheKey)
        return dataURI
    }

    private func reserveDataURIBudget(bytes: Int) -> Bool {
        guard bytes <= maxMDictCachedSingleDataURIBytes,
              resolvedDataURICount < maxMDictResolvedDataURICountPerLookup,
              resolvedDataURIBytes + bytes <= maxMDictResolvedDataURIBytesPerLookup
        else { return false }

        resolvedDataURICount += 1
        resolvedDataURIBytes += bytes
        return true
    }

    private func dataURIByteCount(dataByteCount: Int, mimeType: String) -> Int {
        let base64ByteCount = ((dataByteCount + 2) / 3) * 4
        return "data:\(mimeType);base64,".utf8.count + base64ByteCount
    }

    private func stylesheetText(for key: String) -> String? {
        let cacheKey = resourceCacheKey(for: key)
        if let cached = cachedStylesheets[cacheKey] {
            markStylesheetCacheHit(cacheKey)
            return cached
        }
        guard !missingResourceKeys.contains(cacheKey),
              let data = try? lookupResource(key),
              !data.isEmpty,
              let css = Self.decodeResourceText(data, preferredEncoding: mdxReader.header.encoding)
        else {
            markMissingResource(cacheKey)
            return nil
        }

        let budgetMissCount = dataURIBudgetMissCount
        let resolvedCSS = replaceCSSResources(in: css)
        if budgetMissCount == dataURIBudgetMissCount {
            cacheStylesheet(resolvedCSS, for: cacheKey)
        }
        return resolvedCSS
    }

    private func localStylesheetText() -> String? {
        if didLoadLocalStylesheet {
            return cachedLocalStylesheet
        }

        let cssURL = mdxURL.deletingPathExtension().appendingPathExtension("css")
        guard FileManager.default.fileExists(atPath: cssURL.path) else {
            didLoadLocalStylesheet = true
            return nil
        }
        guard let data = try? Data(contentsOf: cssURL),
              let css = Self.decodeResourceText(data, preferredEncoding: mdxReader.header.encoding)
        else {
            didLoadLocalStylesheet = true
            return nil
        }

        let budgetMissCount = dataURIBudgetMissCount
        let resolvedCSS = replaceCSSResources(in: css)
        if budgetMissCount == dataURIBudgetMissCount {
            cachedLocalStylesheet = resolvedCSS
            didLoadLocalStylesheet = true
        }
        return resolvedCSS
    }

    private func scriptText(for key: String) -> String? {
        guard let data = try? lookupResource(key), !data.isEmpty else { return nil }
        return Self.decodeResourceText(data, preferredEncoding: mdxReader.header.encoding)
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

    private func resourceCacheKey(for key: String) -> String {
        (key.removingPercentEncoding ?? key)
            .components(separatedBy: CharacterSet(charactersIn: "?#"))
            .first?
            .replacingOccurrences(of: "/", with: "\\") ?? key
    }

    private func cacheDataURI(_ dataURI: String, for key: String) {
        let bytes = dataURI.utf8.count
        guard bytes <= maxMDictCachedSingleDataURIBytes else { return }

        if let oldValue = cachedDataURIs[key] {
            dataURICacheBytes -= oldValue.utf8.count
        }
        cachedDataURIs[key] = dataURI
        dataURICacheBytes += bytes
        markDataURICacheHit(key)

        while dataURICacheBytes > maxMDictCachedDataURIBytes,
              let evictedKey = dataURICacheOrder.first {
            dataURICacheOrder.removeFirst()
            if let evicted = cachedDataURIs.removeValue(forKey: evictedKey) {
                dataURICacheBytes -= evicted.utf8.count
            }
        }
    }

    private func cacheStylesheet(_ css: String, for key: String) {
        let bytes = css.utf8.count
        guard bytes <= maxMDictCachedCSSEntryBytes else { return }
        if let oldValue = cachedStylesheets[key] {
            stylesheetCacheBytes -= oldValue.utf8.count
        }
        cachedStylesheets[key] = css
        stylesheetCacheBytes += bytes
        markStylesheetCacheHit(key)

        while stylesheetCacheBytes > maxMDictCachedCSSBytes,
              let evictedKey = stylesheetCacheOrder.first {
            stylesheetCacheOrder.removeFirst()
            if let evicted = cachedStylesheets.removeValue(forKey: evictedKey) {
                stylesheetCacheBytes -= evicted.utf8.count
            }
        }
    }

    private func markDataURICacheHit(_ key: String) {
        dataURICacheOrder.removeAll { $0 == key }
        dataURICacheOrder.append(key)
    }

    private func markStylesheetCacheHit(_ key: String) {
        stylesheetCacheOrder.removeAll { $0 == key }
        stylesheetCacheOrder.append(key)
    }

    private func markMissingResource(_ key: String) {
        guard missingResourceKeys.insert(key).inserted else { return }
        missingResourceOrder.append(key)
        while missingResourceOrder.count > maxMDictMissingResourceCount,
              let evicted = missingResourceOrder.first {
            missingResourceOrder.removeFirst()
            missingResourceKeys.remove(evicted)
        }
    }
}

// MARK: - HTML Link Rewriting

extension MDictDictionary {
    /// Rewrites MDict links so WebKit can render local resources without a scheme handler.
    func resolveLinks(in html: String) -> String {
        resolvedDataURIBytes = 0
        resolvedDataURICount = 0
        dataURIBudgetMissCount = 0

        var result = html
        result = result.replacingOccurrences(
            of: "entry://",
            with: "mdict-entry://"
        )
        result = replaceScriptLinks(in: result)
        result = replaceStylesheetLinks(in: result)
        result = replaceResourceAttributes(in: result)
        result = replaceSourceSets(in: result)
        result = replaceCSSResources(in: result)
        result = replaceAudioConstructors(in: result)
        result = replaceSoundLinks(in: result)
        if let localStylesheet = localStylesheetText() {
            result = "<style>\(localStylesheet)</style>\(result)"
        }
        return result
    }

    func replaceCSSResources(in html: String) -> String {
        replaceMatches(
            in: html,
            regex: Self.cssURLRegex
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

    fileprivate func replaceSoundLinks(in html: String) -> String {
        replaceMatches(
            in: html,
            regex: Self.soundLinkRegex
        ) { match, source in
            guard let keyRange = Range(match.range(at: 1), in: source) else { return nil }
            return dataURI(for: String(source[keyRange]))
        }
    }

    fileprivate func replaceResourceAttributes(in html: String) -> String {
        replaceMatches(
            in: html,
            regex: Self.resourceAttributeRegex
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

    fileprivate func replaceSourceSets(in html: String) -> String {
        replaceMatches(
            in: html,
            regex: Self.sourceSetRegex
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

                    let safeURI = dataURI.replacingOccurrences(of: ",", with: "%2C")
                    let descriptor = parts.dropFirst().joined(separator: " ")
                    return descriptor.isEmpty ? safeURI : "\(safeURI) \(descriptor)"
                }
                .joined(separator: ", ")
            return "\(source[prefixRange])\(rewritten)\(source[suffixRange])"
        }
    }

    fileprivate func replaceStylesheetLinks(in html: String) -> String {
        replaceMatches(
            in: html,
            regex: Self.stylesheetLinkRegex
        ) { match, source in
            guard let keyRange = Range(match.range(at: 1), in: source) else { return nil }
            let key = String(source[keyRange])
            guard shouldResolveResource(key),
                  let css = stylesheetText(for: key)
            else { return nil }

            return "<style>\(css)</style>"
        }
    }

    fileprivate func replaceScriptLinks(in html: String) -> String {
        replaceMatches(
            in: html,
            regex: Self.scriptLinkRegex
        ) { match, source in
            guard let prefixRange = Range(match.range(at: 1), in: source),
                  let keyRange = Range(match.range(at: 2), in: source),
                  let suffixRange = Range(match.range(at: 3), in: source)
            else { return nil }
            let key = String(source[keyRange])
            guard shouldResolveResource(key),
                  let script = scriptText(for: key)
            else { return nil }

            let attributes = Self.preservedScriptAttributes(
                "\(source[prefixRange])\(source[suffixRange])"
            )
            return "<script\(attributes) nonce=\"easydict-mdict\">"
                + "\(Self.escapeInlineScript(script))</script>"
        }
    }

    fileprivate func replaceAudioConstructors(in html: String) -> String {
        replaceMatches(
            in: html,
            regex: Self.audioConstructorRegex
        ) { match, source in
            guard let argumentRange = Range(match.range(at: 1), in: source) else { return nil }
            let rawArgument = String(source[argumentRange])
            let key = rawArgument
                .replacingOccurrences(of: "&quot;", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
            guard shouldResolveResource(key),
                  let dataURI = dataURI(for: key)
            else { return nil }

            return "new Audio(\(Self.javaScriptStringLiteral(dataURI)))"
        }
    }

    fileprivate func replaceMatches(
        in html: String,
        regex: NSRegularExpression,
        replacement: (NSTextCheckingResult, String) -> String?
    )
        -> String {
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

    fileprivate func shouldResolveResource(_ key: String) -> Bool {
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
