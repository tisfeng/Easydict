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
/// Renders a dedicated MDict result page in the WebView. Each dictionary entry
/// is isolated in its own iframe so dictionary CSS cannot override the outer
/// result layout, while loaded dictionaries are managed by `MDictManager`.
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

    private static let scriptNonce = "easydict-mdict"
    private static let webViewScriptName = "MDictWebViewScript"
    private static let entryScriptName = "MDictEntryScript"

    private static var contentSecurityPolicy: String {
        """
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; \
        frame-src 'self' about: data: blob:; child-src 'self' about: data: blob:; \
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
        .mdict-iframe {
          display: block;
          width: 100%;
          border: 0;
          background: transparent;
        }
        </style>
        """
    }

    private static var webViewScript: String {
        Self.scriptHTML(named: Self.webViewScriptName)
    }

    private static var entryScript: String {
        Self.scriptHTML(named: Self.entryScriptName)
    }

    private static var entryDarkStyle: String {
        let darkText = NSColor.mm_hexString(from: NSColor.ez_resultTextDark())
        let darkBG = NSColor.mm_hexString(from: NSColor.ez_resultViewBgDark())

        return """
        <style>
        @media (prefers-color-scheme: dark) {
          html,
          body {
            color: \(darkText);
            background-color: \(darkBG) !important;
            filter: none !important;
          }
          img,
          svg,
          video {
            filter: none !important;
          }
        }
        </style>
        """
    }

    private static func scriptHTML(named scriptName: String) -> String {
        guard let script = scriptText(named: scriptName) else {
            assertionFailure("Missing MDict script resource: \(scriptName)")
            return ""
        }
        return """
        <script nonce="\(scriptNonce)">
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
            let styledContent = Self.wrapWithStyle(content)
            sections.append(DictionaryHTMLSection(title: dict.title, html: styledContent))
            await Task.yield()
        }

        return renderWebViewHTML(word: text, sections: sections)
    }

    private static func wrapWithStyle(_ html: String) -> String {
        let extraCSS = """
        body{margin:8px;padding:0;}\
        img,svg{max-width:100%;height:auto;}\
        a[href^="data:audio"],a[href^="mdict-sound://"],a[href^="sound://"]{\
        display:inline-flex!important;align-items:center;justify-content:center;\
        width:24px!important;height:24px!important;line-height:24px!important;\
        vertical-align:middle;overflow:hidden;}\
        [class*="sound" i],[class*="audio" i],[class*="speaker" i]{font-size:16px;}\
        a[href^="data:audio"] img,a[href^="data:audio"] svg,\
        a[href^="mdict-sound://"] img,a[href^="mdict-sound://"] svg,\
        a[href^="sound://"] img,a[href^="sound://"] svg,\
        input[type="image"][class*="sound" i],input[type="image"][class*="audio" i],\
        input[type="image"][class*="speaker" i],\
        [class*="sound" i] img,[class*="audio" i] img,[class*="speaker" i] img,\
        [class*="sound" i] svg,[class*="audio" i] svg,[class*="speaker" i] svg{\
        width:24px!important;height:24px!important;max-width:24px!important;max-height:24px!important;}\
        a[href^="mdict-entry://"]{cursor:pointer;}
        """
        let style = """
        <style>
        \(extraCSS)\
        </style>
        """
        return contentSecurityPolicy + style + html + entryDarkStyle + entryScript
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
            let escapedHTML = section.html.escapedXMLString()
            return """
            <details class="mdict-section" open>\
            <summary class="mdict-summary">\(title)</summary>\
            <iframe class="mdict-iframe" srcdoc="\(escapedHTML)"></iframe>\
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
        \(webViewScript)
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
