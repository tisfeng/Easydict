//
//  MDictService.swift
//  Easydict
//
//  Created by Kuroda Kayn on 2026/05/01.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - MDictService

/// Query service that looks up words in user-imported MDict (MDX/MDD) dictionaries.
///
/// Renders a dedicated MDict result page in the WebView. Dictionary entries are
/// embedded directly in collapsible sections so WebKit can apply appearance,
/// sizing, and link handling without iframe compensation logic.
@objc(EZMDictService)
@objcMembers
class MDictService: QueryService, @unchecked Sendable {
    // MARK: Internal

    // MARK: - QueryService overrides

    override func serviceType() -> ServiceType {
        .mDict
    }

    override func name() -> String {
        NSLocalizedString("service.mdict.name", comment: "")
    }

    override func apiKeyRequirement() -> ServiceAPIKeyRequirement {
        .none
    }

    override func supportedQueryType() -> EZQueryTextType {
        [.dictionary, .sentence]
    }

    override func intelligentQueryTextType() -> EZQueryTextType {
        [.dictionary, .sentence]
    }

    override func supportLanguagesDictionary() -> MMOrderedDictionary {
        let ordered = MMOrderedDictionary()
        for lang in EZLanguageManager.shared().allLanguages {
            ordered.setObject(lang as NSString, forKey: lang as NSString)
        }
        return ordered
    }

    override func configurationListItems() -> Any? {
        MDictConfigurationView()
    }

    // MARK: - Translation

    @nonobjc
    override func translate(
        _ text: String,
        from: Language,
        to: Language
    ) async throws
        -> QueryResult {
        let dicts = await MDictManager.shared.dictionariesForLookup()
        guard !dicts.isEmpty else {
            throw QueryError.error(
                type: .noResult,
                message: NSLocalizedString(
                    "service.mdict.error.no_dictionaries",
                    comment: ""
                )
            )
        }

        guard let htmlString = await Self.lookupHTML(text, in: dicts) else {
            throw QueryError(type: .noResult)
        }

        result?.htmlString = htmlString
        return result ?? QueryResult()
    }

    // MARK: Private

    private static let scriptNames = [
        "darkreader.min",
        "MDictStyleScript",
        "MDictEntryScript",
    ]

    private static var contentSecurityPolicy: String {
        """
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; \
        img-src data: blob:; media-src data: blob:; font-src data:; \
        style-src 'unsafe-inline'; script-src 'unsafe-inline';">
        """
    }

    private static var webViewStyle: String {
        let lightText = NSColor.mm_hexString(from: NSColor.ez_resultTextLight())
        let lightBG = NSColor.mm_hexString(from: NSColor.ez_resultViewBgLight())
        let darkText = NSColor.mm_hexString(from: NSColor.ez_resultTextDark())
        let darkBG = NSColor.mm_hexString(from: NSColor.ez_resultViewBgDark())

        return """
        <style>
        :root {
          color-scheme: light dark;
          --mdict-text: \(lightText);
          --mdict-bg: \(lightBG);
          --mdict-border: #D8D8D8;
          --mdict-summary-bg: rgba(0, 0, 0, 0.03);
        }
        @media (prefers-color-scheme: dark) {
          :root {
            --mdict-text: \(darkText);
            --mdict-bg: \(darkBG);
            --mdict-border: #707173;
            --mdict-summary-bg: rgba(255, 255, 255, 0.04);
          }
        }
        html,
        body {
          margin: 0;
          padding: 0;
          color: var(--mdict-text);
          background-color: var(--mdict-bg);
          font-family: system-ui;
        }
        .mdict-section {
          display: block;
          margin: 8px 6px 16px;
          border: 1px solid var(--mdict-border);
          border-radius: 7px;
          overflow: hidden;
          background-color: var(--mdict-bg);
        }
        .mdict-section + .mdict-section {
          margin-top: 18px;
        }
        .mdict-summary {
          display: block;
          margin: 0;
          padding: 7px 10px;
          border-bottom: 1px solid var(--mdict-border);
          color: var(--mdict-text);
          background-color: var(--mdict-summary-bg);
          text-align: center;
          font-size: 18px;
          font-weight: 400;
        }
        .mdict-entry {
          padding: 8px;
          color: var(--mdict-text);
          background-color: var(--mdict-bg);
          overflow-wrap: anywhere;
        }
        .mdict-entry img,
        .mdict-entry svg,
        .mdict-entry video {
          max-width: 100%;
          height: auto;
        }
        .mdict-entry a[href^="data:audio"],
        .mdict-entry a[href^="mdict-sound://"],
        .mdict-entry a[href^="sound://"] {
          display: inline-flex !important;
          align-items: center;
          justify-content: center;
          width: 24px !important;
          height: 24px !important;
          line-height: 24px !important;
          vertical-align: middle;
          overflow: hidden;
        }
        .mdict-entry [class*="sound" i],
        .mdict-entry [class*="audio" i],
        .mdict-entry [class*="speaker" i] {
          font-size: 16px;
        }
        .mdict-entry a[href^="data:audio"] img,
        .mdict-entry a[href^="data:audio"] svg,
        .mdict-entry a[href^="mdict-sound://"] img,
        .mdict-entry a[href^="mdict-sound://"] svg,
        .mdict-entry a[href^="sound://"] img,
        .mdict-entry a[href^="sound://"] svg,
        .mdict-entry input[type="image"][class*="sound" i],
        .mdict-entry input[type="image"][class*="audio" i],
        .mdict-entry input[type="image"][class*="speaker" i],
        .mdict-entry [class*="sound" i] img,
        .mdict-entry [class*="audio" i] img,
        .mdict-entry [class*="speaker" i] img,
        .mdict-entry [class*="sound" i] svg,
        .mdict-entry [class*="audio" i] svg,
        .mdict-entry [class*="speaker" i] svg {
          width: 24px !important;
          height: 24px !important;
          max-width: 24px !important;
          max-height: 24px !important;
        }
        .mdict-entry a[href^="mdict-entry://"] {
          cursor: pointer;
        }
        @media (prefers-color-scheme: dark) {
          html,
          body,
          .mdict-entry {
            color: \(darkText);
            background-color: \(darkBG) !important;
            filter: none !important;
          }
          .mdict-entry img,
          .mdict-entry svg,
          .mdict-entry video {
            filter: none !important;
          }
        }
        </style>
        """
    }

    private static var pageScripts: String {
        scriptNames
            .map { Self.scriptHTML(named: $0) }
            .joined(separator: "\n")
    }

    private static func scriptHTML(named scriptName: String) -> String {
        guard let script = scriptText(named: scriptName) else {
            assertionFailure("Missing MDict script resource: \(scriptName)")
            return ""
        }
        return """
        <script>
        \(script)
        </script>
        """
    }

    private static func scriptText(named scriptName: String) -> String? {
        guard let url = Bundle.main.url(forResource: scriptName, withExtension: "js") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    private static func lookupHTML(
        _ text: String,
        in dictionaries: [MDictDictionary]
    ) async
        -> String? {
        var sections: [DictionaryHTMLSection] = []

        for dict in dictionaries {
            if Task.isCancelled { break }
            let definition: String
            do {
                guard let lookupResult = try dict.lookup(text),
                      !lookupResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { continue }
                definition = lookupResult
            } catch {
                logError("MDictService: lookup failed in \(dict.title): \(error)")
                continue
            }

            let content = dict.isHTML ? definition : Self.plainTextToHTML(definition)
            sections.append(DictionaryHTMLSection(title: dict.title, html: content))
            await Task.yield()
        }

        return renderWebViewHTML(word: text, sections: sections)
    }

    private static func renderWebViewHTML(
        word _: String,
        sections: [DictionaryHTMLSection]
    )
        -> String? {
        let visibleSections = sections.filter {
            !$0.html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !visibleSections.isEmpty else { return nil }

        let sectionsHTML = visibleSections.map { section in
            let title = section.title.escapedXMLString()
            return """
            <details class="mdict-section" open>\
            <summary class="mdict-summary">\(title)</summary>\
            <div class="mdict-entry">\(section.html)</div>\
            </details>
            """
        }.joined(separator: "\n")

        return """
        <!doctype html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="color-scheme" content="light dark">
        \(contentSecurityPolicy)
        \(webViewStyle)
        \(pageScripts)
        </head>
        <body>
        \(sectionsHTML)
        </body>
        </html>
        """
    }

    private static func plainTextToHTML(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        let paragraphs = escaped
            .components(separatedBy: "\n\n")
            .map { "<p>\($0.replacingOccurrences(of: "\n", with: "<br>"))</p>" }
            .joined()
        return "<div>\(paragraphs)</div>"
    }
}
