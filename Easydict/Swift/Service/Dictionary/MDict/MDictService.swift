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

        let sections = await Self.lookupSections(text, in: dicts)

        guard let renderResult = DictionaryHTMLRenderer.render(word: text, sections: sections) else {
            throw QueryError(type: .noResult)
        }

        result?.htmlString = renderResult.htmlString
        return result ?? QueryResult()
    }

    // MARK: Private

    private static func lookupSections(
        _ text: String,
        in dictionaries: [MDictDictionary]
    ) async
        -> [DictionaryHTMLSection] {
        await Task(priority: .userInitiated) {
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
            }

            return sections
        }.value
    }

    private static func wrapWithStyle(_ html: String) -> String {
        let scriptNonce = "easydict-mdict"
        let contentSecurityPolicy = """
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; \
        img-src data: blob:; media-src data: blob:; font-src data:; \
        style-src 'unsafe-inline'; script-src 'nonce-\(scriptNonce)';">
        """
        let extraCSS = """
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
        let style = DictionaryHTMLRenderer.entryStyle(bodyMargin: 8, extraCSS: extraCSS)
        let script = """
        <script nonce="\(scriptNonce)">\
        document.addEventListener('click',function(event){\
        var link=event.target&&event.target.closest?event.target.closest('a[href]'):null;\
        if(!link){return;}\
        var href=link.getAttribute('href')||'';\
        var source=audioSource(link,href);\
        if(source){event.preventDefault();playAudio(source);return;}\
        if(handleAnchorLink(href)){event.preventDefault();return;}\
        },true);\
        function audioSource(link,href){\
        if(link.matches('a[href^="data:audio"],a[href^="mdict-sound://"],a[href^="sound://"]')){return href;}\
        var match=href.match(/^\\s*javascript:\\s*new\\s+Audio\\s*\\(\\s*(['"])(data:[^'"]+)\\1\\s*\\)/i);\
        return match?match[2]:null;\
        }\
        function playAudio(source){\
        if(!source){return;}\
        window.__mdictAudio=new Audio(source);\
        window.__mdictAudio.play();\
        }\
        function handleAnchorLink(href){\
        var hash=href.charAt(0)==='#'?href:(href.indexOf('#')>=0?href.slice(href.indexOf('#')):'');\
        if(!hash||hash.length<2){return false;}\
        var id=decodeURIComponent(hash.slice(1));\
        var target=document.getElementById(id)||document.getElementsByName(id)[0];\
        if(!target){return false;}\
        target.scrollIntoView({block:'start'});\
        return true;\
        }\
        </script>
        """
        return contentSecurityPolicy + style + script + html
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
