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
/// Renders HTML definitions via the same iframe-based layout used by
/// `AppleDictionary`. Loaded dictionaries are managed by `MDictManager`.
@objc(EZMDictService)
@objcMembers
class MDictService: QueryService, @unchecked Sendable {
    // MARK: - QueryService overrides

    override func serviceType() -> ServiceType {
        .mdict
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
    ) async throws -> QueryResult {
        let dicts = await MDictManager.shared.enabledDictionaries
        guard !dicts.isEmpty else {
            throw QueryError.error(
                type: .noResult,
                message: NSLocalizedString(
                    "service.mdict.error.no_dictionaries",
                    comment: ""
                )
            )
        }

        var iframesHTML = ""
        var bigWordHTML = "<h2 class=\"big-word-title\">\(text)</h2>"

        let baseHTML = loadBaseHTML()

        for dict in dicts {
            guard let definition = try dict.lookup(text),
                  !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { continue }

            let content = dict.isHTML ? definition : plainTextToHTML(definition)
            let styledContent = wrapWithStyle(content)
            let escaped = styledContent.escapedXMLString()
            let iframe = "<iframe class=\"custom-iframe-container\" srcdoc=\"\(escaped)\"></iframe>"
            let details = "\(bigWordHTML)<details open><summary>\(dict.title)</summary>\(iframe)</details>"
            bigWordHTML = ""
            iframesHTML += details
        }

        guard !iframesHTML.isEmpty else {
            throw QueryError(type: .noResult)
        }

        let full = (baseHTML ?? "<html><body></body></html>")
            .replacingOccurrences(of: "</body>", with: "\(iframesHTML)</body>")

        result?.htmlString = full
        return result ?? QueryResult()
    }

    // MARK: Private

    private func loadBaseHTML() -> String? {
        Bundle.main.path(forResource: "apple-dictionary", ofType: "html")
            .flatMap { try? String(contentsOfFile: $0, encoding: .utf8) }
    }

    private func wrapWithStyle(_ html: String) -> String {
        let lightText = NSColor.mm_hexString(from: NSColor.ez_resultTextLight())
        let lightBG = NSColor.mm_hexString(from: NSColor.ez_resultViewBgLight())
        let darkBG = NSColor.mm_hexString(from: NSColor.ez_resultViewBgDark())

        let style = """
        <style>\
        body{margin:8px;color:\(lightText);background-color:\(lightBG);font-family:'system-ui';}\
        @media(prefers-color-scheme:dark){body{background-color:\(darkBG);\
        filter:invert(0.85) hue-rotate(185deg) saturate(200%) brightness(120%);}}\
        a[href^="mdict-entry://"]{cursor:pointer;}\
        </style>
        """
        return style + html
    }

    private func plainTextToHTML(_ text: String) -> String {
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
