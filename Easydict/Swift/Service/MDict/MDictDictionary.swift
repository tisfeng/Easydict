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
/// for `entry://` and `sound://` links found inside MDX definitions.
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
        var definition = try mdxReader.lookup(word)

        if definition == nil, !mdxReader.header.keyCaseSensitive {
            definition = try mdxReader.lookup(word.lowercased())
                ?? mdxReader.lookup(word.capitalized)
        }

        guard let raw = definition else { return nil }

        if isHTML {
            return resolveLinks(in: raw)
        }
        return raw
    }

    /// Returns raw binary data for a resource key (used by MDD files).
    func lookupResource(_ key: String) throws -> Data? {
        let normalizedKey = key.hasPrefix("\\") ? String(key.dropFirst()) : key
        for reader in mddReaders {
            if let data = try reader.lookupData(for: normalizedKey) {
                return data
            }
        }
        return nil
    }

    // MARK: Private

    private let mdxReader: MDictReader
    private let mddReaders: [MDictReader]

    /// Replace `entry://word` links with a lookup-triggering JS call, and
    /// `sound://path` links with a data-URI or removal so they degrade gracefully.
    private func resolveLinks(in html: String) -> String {
        // Keep the HTML as-is; the WKWebView SchemeHandler (if added) will
        // intercept mdict:// URLs. Strip the scheme prefix for now so links
        // don't navigate away from the result page.
        var result = html
        result = result.replacingOccurrences(
            of: "entry://",
            with: "mdict-entry://"
        )
        result = result.replacingOccurrences(
            of: "sound://",
            with: "mdict-sound://"
        )
        return result
    }
}

// MARK: - Equatable

extension MDictDictionary: Equatable {
    static func == (lhs: MDictDictionary, rhs: MDictDictionary) -> Bool {
        lhs.mdxURL == rhs.mdxURL
    }
}

// MARK: - Identifiable

extension MDictDictionary: Identifiable {
    var id: URL { mdxURL }
}
