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
        let script = """
        <script nonce="\(scriptNonce)">
        var mdictResizeTimer = 0;
        function getIframeDocument(iframe) {
          try {
            return iframe.contentDocument || iframe.contentWindow.document;
          } catch (error) {
            return null;
          }
        }
        function resizeIframes() {
          var iframes = document.querySelectorAll('iframe.mdict-iframe');
          for (var i = 0; i < iframes.length; i++) {
            var iframe = iframes[i];
            var iframeDocument = getIframeDocument(iframe);
            if (!iframeDocument || !iframeDocument.body || !iframeDocument.documentElement) {
              continue;
            }
            setStyleIfChanged(iframeDocument.body, 'margin', '8px');
            setStyleIfChanged(iframeDocument.body, 'padding', '0');
            improveIframeDarkText(iframeDocument);
            observeIframeContent(iframe, iframeDocument);
            var height = iframeContentHeight(iframeDocument);
            if (height > 0) {
              setStyleIfChanged(iframe, 'height', height + 'px');
            }
          }
        }
        function iframeContentHeight(iframeDocument) {
          var body = iframeDocument.body;
          var view = iframeDocument.defaultView;
          var bodyRect = body.getBoundingClientRect();
          var bodyTop = bodyRect.top;
          var height = Math.ceil(bodyRect.height);
          var elements = body.querySelectorAll('*');
          for (var i = 0; i < elements.length; i++) {
            var element = elements[i];
            var tagName = element.tagName ? element.tagName.toLowerCase() : '';
            if (['script', 'style', 'link', 'meta'].indexOf(tagName) >= 0) {
              continue;
            }
            var style = view.getComputedStyle(element);
            if (style.display === 'none' || style.position === 'fixed') {
              continue;
            }
            var rect = element.getBoundingClientRect();
            if (rect.width === 0 && rect.height === 0) {
              continue;
            }
            height = Math.max(height, Math.ceil(rect.bottom - bodyTop));
          }
          var bodyStyle = view.getComputedStyle(body);
          var marginBottom = parseFloat(bodyStyle.marginBottom) || 0;
          return Math.max(1, height + marginBottom);
        }
        function observeIframeContent(iframe, iframeDocument) {
          if (iframe.dataset.mdictContentObserved === 'true') {
            return;
          }
          iframe.dataset.mdictContentObserved = 'true';
          iframeDocument.addEventListener('click', scheduleIframeUpdate, true);
          iframeDocument.addEventListener('input', scheduleIframeUpdate, true);
          iframeDocument.addEventListener('transitionend', scheduleIframeUpdate, true);
          iframeDocument.addEventListener('animationend', scheduleIframeUpdate, true);
          if (iframe.contentWindow && iframe.contentWindow.MutationObserver) {
            var observer = new iframe.contentWindow.MutationObserver(scheduleIframeUpdate);
            observer.observe(iframeDocument.body, {
              attributes: true,
              childList: true,
              subtree: true,
              characterData: true
            });
          }
        }
        function scheduleIframeUpdate() {
          if (mdictResizeTimer) {
            clearTimeout(mdictResizeTimer);
          }
          mdictResizeTimer = setTimeout(function() {
            mdictResizeTimer = 0;
            updateAllIframeStyle();
          }, 80);
        }
        function setStyleIfChanged(element, property, value) {
          if (element.style[property] !== value) {
            element.style[property] = value;
          }
        }
        function isDarkMode() {
          return window.matchMedia &&
            window.matchMedia('(prefers-color-scheme: dark)').matches;
        }
        function improveIframeDarkText(iframeDocument) {
          if (!isDarkMode()) {
            return;
          }
          var elements = iframeDocument.body.querySelectorAll('*');
          improveElementTextColor(iframeDocument.body, iframeDocument);
          for (var i = 0; i < elements.length; i++) {
            improveElementTextColor(elements[i], iframeDocument);
          }
        }
        function improveElementTextColor(element, iframeDocument) {
          var tagName = element.tagName ? element.tagName.toLowerCase() : '';
          if (['img', 'svg', 'path', 'audio', 'video', 'source'].indexOf(tagName) >= 0) {
            return;
          }
          var style = iframeDocument.defaultView.getComputedStyle(element);
          var textColor = parseColor(style.color);
          if (!textColor || textColor.a === 0) {
            return;
          }
          var backgroundColor = nearestBackgroundColor(element, iframeDocument);
          var readableColor = readableTextColor(textColor, backgroundColor);
          if (!readableColor) {
            return;
          }
          setStyleIfChanged(element, 'color', readableColor);
        }
        function nearestBackgroundColor(element, iframeDocument) {
          var current = element;
          while (current && current.nodeType === 1) {
            var style = iframeDocument.defaultView.getComputedStyle(current);
            var backgroundColor = parseColor(style.backgroundColor);
            if (backgroundColor && backgroundColor.a > 0.05) {
              return backgroundColor;
            }
            current = current.parentElement;
          }
          return { r: 48, g: 49, b: 50, a: 1 };
        }
        function readableTextColor(textColor, backgroundColor) {
          if (contrastRatio(textColor, backgroundColor) >= 4.5) {
            return null;
          }
          var targetIsWhite = relativeLuminance(backgroundColor) < 0.45;
          for (var amount = 0.18; amount <= 0.9; amount += 0.08) {
            var mixed = targetIsWhite ?
              mixWithWhite(textColor, amount) :
              mixWithBlack(textColor, amount);
            if (contrastRatio(mixed, backgroundColor) >= 4.5) {
              return rgbString(mixed);
            }
          }
          return targetIsWhite ? 'rgb(224, 224, 224)' : 'rgb(38, 38, 38)';
        }
        function parseColor(value) {
          if (!value || value === 'transparent') {
            return null;
          }
          var match = value.match(/rgba?\\(([^)]+)\\)/i);
          if (!match) {
            return null;
          }
          var parts = match[1].split(',').map(function(part) {
            return part.trim();
          });
          if (parts.length < 3) {
            return null;
          }
          return {
            r: parseFloat(parts[0]),
            g: parseFloat(parts[1]),
            b: parseFloat(parts[2]),
            a: parts.length > 3 ? parseFloat(parts[3]) : 1
          };
        }
        function mixWithWhite(color, amount) {
          return {
            r: color.r + (255 - color.r) * amount,
            g: color.g + (255 - color.g) * amount,
            b: color.b + (255 - color.b) * amount,
            a: color.a
          };
        }
        function mixWithBlack(color, amount) {
          return {
            r: color.r * (1 - amount),
            g: color.g * (1 - amount),
            b: color.b * (1 - amount),
            a: color.a
          };
        }
        function rgbString(color) {
          return 'rgb(' + Math.round(color.r) + ', ' +
            Math.round(color.g) + ', ' + Math.round(color.b) + ')';
        }
        function contrastRatio(foreground, background) {
          var lighter = Math.max(relativeLuminance(foreground), relativeLuminance(background));
          var darker = Math.min(relativeLuminance(foreground), relativeLuminance(background));
          return (lighter + 0.05) / (darker + 0.05);
        }
        function relativeLuminance(color) {
          var values = [color.r, color.g, color.b].map(function(value) {
            value = value / 255;
            return value <= 0.03928 ? value / 12.92 : Math.pow((value + 0.055) / 1.055, 2.4);
          });
          return 0.2126 * values[0] + 0.7152 * values[1] + 0.0722 * values[2];
        }
        function notifyContentHeight() {
          if (!(window.webkit && window.webkit.messageHandlers)) {
            return;
          }
          var height = Math.max(
            document.body.scrollHeight,
            document.documentElement.scrollHeight,
            Math.ceil(document.body.getBoundingClientRect().height)
          );
          window.webkit.messageHandlers.objcHandler.postMessage({
            method: 'noteToUpdateScrollHeight',
            scrollHeight: height
          });
        }
        function updateAllIframeStyle() {
          resizeIframes();
          notifyContentHeight();
          [50, 250, 750, 1500].forEach(function(delay) {
            setTimeout(function() {
              resizeIframes();
              notifyContentHeight();
            }, delay);
          });
        }
        function changeIframeBodyFontSize(fontSizeRatio) {
          var percentFontSize = fontSizeRatio * 100 + '%';
          document.body.style.fontSize = percentFontSize;
          var iframes = document.querySelectorAll('iframe.mdict-iframe');
          for (var i = 0; i < iframes.length; i++) {
            var iframeDocument = getIframeDocument(iframes[i]);
            if (iframeDocument && iframeDocument.body) {
              iframeDocument.body.style.fontSize = percentFontSize;
            }
          }
        }
        function attachIframeLoadHandlers() {
          var iframes = document.querySelectorAll('iframe.mdict-iframe');
          for (var i = 0; i < iframes.length; i++) {
            if (iframes[i].dataset.mdictObserved === 'true') {
              continue;
            }
            iframes[i].dataset.mdictObserved = 'true';
            iframes[i].addEventListener('load', updateAllIframeStyle);
          }
        }
        document.addEventListener('DOMContentLoaded', function() {
          attachIframeLoadHandlers();
          updateAllIframeStyle();
        });
        window.addEventListener('load', updateAllIframeStyle);
        window.addEventListener('resize', updateAllIframeStyle);
        if (document.fonts && document.fonts.ready) {
          document.fonts.ready.then(updateAllIframeStyle);
        }
        </script>
        """
        return script
    }

    private static var entryScript: String {
        """
        <script nonce="\(scriptNonce)">
        document.addEventListener('click', function(event) {
          var link = event.target && event.target.closest ? event.target.closest('a[href]') : null;
          if (!link) {
            return;
          }
          var href = link.getAttribute('href') || '';
          if (event.defaultPrevented) {
            return;
          }
          var source = audioSource(link, href);
          if (source) {
            event.preventDefault();
            playAudio(source);
            return;
          }
          if (isEmptyHashLink(href) || handleAnchorLink(href)) {
            event.preventDefault();
          }
        }, false);
        function audioSource(link, href) {
          if (link.matches('a[href^="data:audio"],a[href^="mdict-sound://"],a[href^="sound://"]')) {
            return href;
          }
          var match = href.match(/^\\s*javascript:\\s*new\\s+Audio\\s*\\(\\s*(['"])(data:[^'"]+)\\1\\s*\\)/i);
          return match ? match[2] : null;
        }
        function playAudio(source) {
          if (!source) {
            return;
          }
          window.__mdictAudio = new Audio(source);
          window.__mdictAudio.play();
        }
        function handleAnchorLink(href) {
          var hash = samePageHash(href);
          if (!hash || hash.length < 2) {
            return false;
          }
          var id = decodeHash(hash.slice(1));
          var target = document.getElementById(id) || document.getElementsByName(id)[0];
          if (!target) {
            return false;
          }
          setTimeout(function() {
            scrollParentToTarget(target);
          }, 0);
          return true;
        }
        function isEmptyHashLink(href) {
          var trimmed = href.trim();
          return trimmed === '#' ||
            /^javascript:\\s*(?:void\\s*\\(\\s*0\\s*\\)|;?)\\s*;?$/i.test(trimmed);
        }
        function samePageHash(href) {
          var trimmed = href.trim();
          if (trimmed.charAt(0) === '#') {
            return trimmed;
          }
          if (/^[a-z][a-z0-9+.-]*:/i.test(trimmed)) {
            return '';
          }
          var hashIndex = trimmed.indexOf('#');
          return hashIndex >= 0 ? trimmed.slice(hashIndex) : '';
        }
        function decodeHash(value) {
          try {
            return decodeURIComponent(value);
          } catch (error) {
            return value;
          }
        }
        function scrollParentToTarget(target) {
          try {
            var frame = window.frameElement;
            if (!frame || !window.parent) {
              target.scrollIntoView({ block: 'start' });
              return;
            }
            if (window.parent.updateAllIframeStyle) {
              window.parent.updateAllIframeStyle();
            }
            var frameRect = frame.getBoundingClientRect();
            var targetRect = target.getBoundingClientRect();
            var parentY = window.parent.scrollY || window.parent.pageYOffset || 0;
            var top = parentY + frameRect.top + targetRect.top - 8;
            window.parent.scrollTo(0, Math.max(0, top));
          } catch (error) {
            target.scrollIntoView({ block: 'start' });
          }
        }
        </script>
        """
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
