//
//  GlassMiniResultText.swift
//  Easydict
//

import Foundation

/// Adapts translation and dictionary results to the mini window's selectable text surface.
enum GlassMiniResultText {
    /// Prefer the provider's plain text, preserving its whitespace and math delimiters.
    static func plainText(from result: QueryResult) -> String? {
        if let text = nonempty(result.translatedText) { return text }

        let parts = result.wordResult?.parts?.compactMap { part -> String? in
            let meanings = joined(part.means, separator: "; ")
            guard !meanings.isEmpty else { return nil }
            return joined([part.part ?? "", meanings], separator: " ")
        } ?? []
        let words = result.wordResult?.simpleWords?.compactMap { entry -> String? in
            let meanings = joined(entry.means ?? [], separator: "; ")
            guard !meanings.isEmpty else { return nonempty(entry.word) }
            return joined([entry.word, entry.part ?? "", meanings], separator: " ")
        } ?? []
        if let text = nonempty(joined(parts + words, separator: "\n")) { return text }

        // Apple Dictionary already supplies the system dictionary's plain-text definitions.
        return nonempty(joined(result.innerTexts ?? [], separator: "\n\n"))
    }

    /// Parses dictionary HTML without WebKit, scripts, or external resource loads.
    /// Call off the main thread: MDict pages can contain large embedded styles and scripts.
    static func htmlText(from fragments: [String]) -> String {
        joined(fragments.map { htmlText($0, depth: 0) }, separator: "\n\n")
    }

    private static let ignoredElements: Set<String> = [
        "head", "script", "style", "template", "noscript", "svg", "audio", "video",
    ]
    private static let blockElements: Set<String> = [
        "address", "article", "aside", "blockquote", "br", "dd", "details", "div", "dl", "dt",
        "figcaption", "figure", "footer", "h1", "h2", "h3", "h4", "h5", "h6", "header", "hr",
        "li", "main", "ol", "p", "pre", "section", "summary", "table", "tr", "ul",
    ]

    private static func nonempty(_ text: String?) -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }

    private static func joined(_ values: [String], separator: String) -> String {
        values.compactMap { nonempty($0)?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: separator)
    }

    private static func htmlText(_ html: String, depth: Int) -> String {
        guard depth < 256,
              let document = try? XMLDocument(
                  xmlString: html,
                  options: [.documentTidyHTML, .nodeLoadExternalEntitiesNever]
              ),
              let root = document.rootElement()
        else { return "" }

        var output = ""
        appendText(root, to: &output, depth: depth)
        return output.components(separatedBy: "\n")
            .map { $0.split(whereSeparator: \.isWhitespace).joined(separator: " ") }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private static func appendText(_ node: XMLNode, to output: inout String, depth: Int) {
        guard depth < 256 else { return }
        if node.kind == .text {
            // HTML source formatting is whitespace, not a paragraph break.
            output += (node.stringValue ?? "").replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            return
        }
        guard let element = node as? XMLElement else { return }
        let name = (element.localName ?? element.name ?? "").lowercased()
        guard !ignoredElements.contains(name), element.attribute(forName: "hidden") == nil else { return }

        if name == "iframe" {
            // Apple Dictionary's result shell embeds definitions in escaped srcdoc attributes.
            if let source = element.attribute(forName: "srcdoc")?.stringValue {
                output += "\n" + htmlText(source, depth: depth + 1) + "\n"
            }
            return
        }

        let isBlock = blockElements.contains(name)
        if isBlock { output += "\n" }
        for child in element.children ?? [] {
            appendText(child, to: &output, depth: depth + 1)
        }
        if isBlock { output += "\n" }
        if name == "td" || name == "th" { output += " " }
    }
}
