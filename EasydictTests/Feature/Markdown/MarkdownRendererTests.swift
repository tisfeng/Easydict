//
//  MarkdownRendererTests.swift
//  EasydictTests
//
//  Created by Lin on 2026/4/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
@testable import Easydict
import Testing

// MARK: - MarkdownRendererTests

/// Behavior tests for ``MarkdownRenderer``. Cover the syntactic forms emitted
/// by AI/LLM translation services and verify streaming-safety: incomplete
/// markers must never throw and an unterminated fence renders to the buffer's
/// current end. UI styling values are checked through attribute spot checks
/// rather than full attributed-string equality.
@Suite("Markdown Renderer", .tags(.markdown, .unit))
struct MarkdownRendererTests {
    // MARK: Internal

    @Test("Plain paragraph text renders unchanged")
    func plainText() {
        let result = renderer.render("Hello world.")
        #expect(result.string.trimmingCharacters(in: .newlines) == "Hello world.")
    }

    @Test("ATX heading levels apply scaled fonts")
    func headings() {
        let result = renderer.render("## Translation\nbody text")
        #expect(result.string.contains("Translation"))
        #expect(result.string.contains("body text"))

        let firstFont = result.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        #expect(firstFont != nil)
        #expect((firstFont?.pointSize ?? 0) > baseSize)
    }

    @Test("Bold emphasis applies a bold font run")
    func boldRun() {
        let result = renderer.render("This is **bold** text.")
        let boldRange = (result.string as NSString).range(of: "bold")
        #expect(boldRange.location != NSNotFound)
        let font = result.attribute(.font, at: boldRange.location, effectiveRange: nil) as? NSFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.bold) == true)
    }

    @Test("Italic emphasis applies an italic font run")
    func italicRun() {
        let result = renderer.render("This is *italic* text.")
        let range = (result.string as NSString).range(of: "italic")
        #expect(range.location != NSNotFound)
        let font = result.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.italic) == true)
    }

    @Test("Spaced asterisks in expressions stay literal")
    func spacedAsterisksStayLiteral() {
        let result = renderer.render("2 * 3 * 4")
        #expect(result.string == "2 * 3 * 4")
    }

    @Test("Inline code carries a monospaced font and background")
    func inlineCode() {
        let result = renderer.render("Run `swift build` now.")
        let range = (result.string as NSString).range(of: "swift build")
        #expect(range.location != NSNotFound)
        let font = result.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
        #expect(font?.fontName.lowercased().contains("mono") == true ||
            font?.fontDescriptor.symbolicTraits.contains(.monoSpace) == true)
    }

    @Test("Fenced code block renders body without fence markers")
    func fencedCodeBlock() {
        let source = "Before\n```\nlet x = 1\n```\nAfter"
        let result = renderer.render(source)
        #expect(result.string.contains("let x = 1"))
        #expect(!result.string.contains("```"))
    }

    @Test("Unterminated fence renders to end of input")
    func unterminatedFence() {
        let source = "Intro\n```\npartial code line"
        let result = renderer.render(source)
        #expect(result.string.contains("partial code line"))
    }

    @Test("Blockquote prefix is stripped from rendered text")
    func blockquote() {
        let result = renderer.render("> a note\n> continued")
        #expect(result.string.contains("a note"))
        #expect(!result.string.contains("> a note"))
    }

    @Test("Unordered list items use a bullet marker")
    func unorderedList() {
        let result = renderer.render("- first\n- second")
        #expect(result.string.contains("•"))
        #expect(result.string.contains("first"))
        #expect(result.string.contains("second"))
    }

    @Test("Ordered list items keep their numbering")
    func orderedList() {
        let result = renderer.render("1. alpha\n2. beta")
        #expect(result.string.contains("1."))
        #expect(result.string.contains("2."))
        #expect(result.string.contains("alpha"))
    }

    @Test("Inline link sets a .link attribute")
    func link() {
        let result = renderer.render("Visit [Apple](https://apple.com).")
        let range = (result.string as NSString).range(of: "Apple")
        #expect(range.location != NSNotFound)
        let url = result.attribute(.link, at: range.location, effectiveRange: nil) as? URL
        #expect(url?.absoluteString == "https://apple.com")
    }

    @Test("Empty input produces an empty attributed string")
    func emptyInput() {
        let result = renderer.render("")
        #expect(result.length == 0)
    }

    @Test("Streaming partial bold marker does not crash and falls back to literal")
    func partialBoldMarker() {
        let result = renderer.render("partial **bold without close")
        #expect(result.string.contains("partial"))
        #expect(result.string.contains("bold without close"))
    }

    @Test("Single-line output has no trailing newline")
    func noTrailingNewline() {
        let result = renderer.render("Hello")
        #expect(result.string == "Hello")
    }

    @Test("Multi-block output does not end with a newline")
    func multiBlockNoTrailingNewline() {
        let result = renderer.render("## Title\n\nBody paragraph.\n\n")
        #expect(!result.string.hasSuffix("\n"))
        #expect(result.string.contains("Title"))
        #expect(result.string.contains("Body paragraph."))
    }

    @Test("Plain paragraphs preserve leading spaces and tabs")
    func plainParagraphPreservesLeadingWhitespace() {
        let result = renderer.render("  indented line\n\tTabbed line")
        #expect(result.string == "  indented line\n\tTabbed line")
    }

    @Test("In-word underscores stay literal so identifiers survive")
    func inWordUnderscoreStaysLiteral() {
        let result = renderer.render("path is foo_bar_baz today")
        #expect(result.string.contains("foo_bar_baz"))
    }

    @Test("Underscore italics still apply at word boundaries")
    func underscoreItalicsAtWordBoundaries() {
        let result = renderer.render("see _italic_ here")
        let range = (result.string as NSString).range(of: "italic")
        #expect(range.location != NSNotFound)
        let font = result.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
        #expect(font?.fontDescriptor.symbolicTraits.contains(.italic) == true)
        #expect(!result.string.contains("_italic_"))
    }

    @Test("Triple asterisk renders bold and italic together")
    func tripleAsteriskBoldItalic() {
        let result = renderer.render("This is ***super important*** here.")
        let range = (result.string as NSString).range(of: "super important")
        #expect(range.location != NSNotFound)
        let font = result.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont
        let traits = font?.fontDescriptor.symbolicTraits
        #expect(traits?.contains(.bold) == true)
        #expect(traits?.contains(.italic) == true)
        #expect(!result.string.contains("***"))
    }

    @Test("Mixed block content keeps each block readable")
    func mixedContent() {
        let source = """
        ## Translation
        在 TODOS.md 中标记里程碑 0。

        > **Marked** → 标记
        > **TODOS.md** → TODOS.md

        - First item
        - Second item
        """
        let result = renderer.render(source)
        let plain = result.string
        #expect(plain.contains("Translation"))
        #expect(plain.contains("在 TODOS.md 中标记里程碑 0。"))
        #expect(plain.contains("Marked"))
        #expect(plain.contains("First item"))
        #expect(plain.contains("Second item"))
        #expect(!plain.contains("**"))
        #expect(!plain.contains("##"))
    }

    @Test("Renderer handles a few hundred chars under streaming budget")
    func streamingBudget() {
        let source = String(repeating: "## Heading\n**bold** and *italic* with `code`.\n", count: 16)
        let start = Date()
        for _ in 0 ..< 30 {
            _ = renderer.render(source)
        }
        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 1.0)
    }

    @MainActor
    @Test("Leading terminal symbols do not replace the font of the entire label", arguments: [false, true])
    func terminalSymbolFont(markdown: Bool) throws {
        let label: EZLabel = markdown ? MarkdownLabel(frame: .zero) : EZLabel(frame: .zero)
        let font = NSFont.systemFont(ofSize: 18)
        label.font = font
        let source = "\u{E0B6} Hello 翻译内容\nSecond line 第二行"
        label.text = source
        let storage = try #require(label.textStorage)

        for _ in 0 ..< 3 {
            storage.fixAttributes(in: NSRange(location: 0, length: storage.length))
            label.updateDisplayedText()
        }

        #expect(label.font?.fontName == font.fontName)
        for text in ["Hello", "翻译内容"] {
            let range = (storage.string as NSString).range(of: text)
            let textFont = try #require(storage.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont)
            #expect(textFont.fontName != "LastResort")
            #expect(textFont.pointSize == 18)
        }
        #expect(storage.string == source)
    }

    @Test("Nested lists keep continuation and child indentation")
    func nestedLists() throws {
        let result = renderer.render("- **Parent**\n  - Child\n    continued\n- Next")
        let parent = (result.string as NSString).range(of: "Parent")
        let child = (result.string as NSString).range(of: "Child")
        let continued = (result.string as NSString).range(of: "continued")
        let next = (result.string as NSString).range(of: "Next")
        let parentStyle = try #require(result.attribute(
            .paragraphStyle,
            at: parent.location,
            effectiveRange: nil
        ) as? NSParagraphStyle)
        let childStyle = try #require(result.attribute(
            .paragraphStyle,
            at: child.location,
            effectiveRange: nil
        ) as? NSParagraphStyle)
        let continuedStyle = try #require(result.attribute(
            .paragraphStyle,
            at: continued.location,
            effectiveRange: nil
        ) as? NSParagraphStyle)
        let nextStyle = try #require(result.attribute(
            .paragraphStyle,
            at: next.location,
            effectiveRange: nil
        ) as? NSParagraphStyle)
        #expect(childStyle.headIndent > parentStyle.headIndent)
        #expect(continuedStyle.headIndent == childStyle.headIndent)
        #expect(nextStyle.firstLineHeadIndent == parentStyle.firstLineHeadIndent)
        #expect(renderer.render("-\n  - Child").string == "•\t\n•\tChild")
    }

    @Test("Pipe tables use native cells and preserve column alignment")
    func tableLayout() throws {
        let result = renderer.render("| Word | Meaning |\n| :--- | ---: |\n| **envisage** | 设想 |\n\nAfter")
        let word = (result.string as NSString).range(of: "envisage")
        let meaning = (result.string as NSString).range(of: "设想")
        let after = (result.string as NSString).range(of: "After")
        let wordStyle = try #require(result.attribute(
            .paragraphStyle,
            at: word.location,
            effectiveRange: nil
        ) as? NSParagraphStyle)
        let meaningStyle = try #require(result.attribute(
            .paragraphStyle,
            at: meaning.location,
            effectiveRange: nil
        ) as? NSParagraphStyle)
        let afterStyle = try #require(result.attribute(
            .paragraphStyle,
            at: after.location,
            effectiveRange: nil
        ) as? NSParagraphStyle)
        #expect(wordStyle.textBlocks.first is NSTextTableBlock)
        #expect(meaningStyle.alignment == .right)
        #expect(afterStyle.textBlocks.isEmpty)
        #expect(!result.string.contains("**"))
    }

    @Test("Supported delimiters typeset fractions and retain TeX source", arguments: [
        #"$\frac{1}{2}$"#, #"\(\frac{1}{2}\)"#, #"$$\frac{1}{2}$$"#, #"\[\frac{1}{2}\]"#,
        #"$$\begin{align*}x &= 1 \\ y &= 2\end{align*}$$"#,
    ])
    func mathematicalDelimiters(source: String) throws {
        let result = renderer.render(source)
        let attachment = try #require(result.attribute(.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment)
        #expect(attachment.bounds.height > baseSize)
        #expect(result.attribute(.markdownMathSource, at: 0, effectiveRange: nil) as? String == source)
    }

    @MainActor
    @Test("Formula source survives streaming, code spans, and selection copy")
    func mathSourcePreservation() throws {
        for source in [#"\(\frac{1}{"#, #"$\unknowncommand{x}$"#, #"Prices: $5 and $10"#, "$$\n- x^2\n\n> y"] {
            #expect(renderer.render(source).string == source)
        }
        #expect(renderer.render(#"`$x_1$` and ``\(x^2\)``"#).string == #"$x_1$ and \(x^2\)"#)
        #expect(renderer.render("```latex\n$x$\n```").string == "$x$")
        #expect(renderer.render("Cost **$5** and **$10**.").string == "Cost $5 and $10.")
        let linked = renderer.render("[price](https://example.com/$USD)")
        #expect(linked.string == "price")
        #expect((linked.attribute(.link, at: 0, effectiveRange: nil) as? URL)?
            .absoluteString == "https://example.com/$USD")
        let label = MarkdownLabel(frame: NSRect(x: 0, y: 0, width: 120, height: 200))
        let source = #"Formula: $\frac{1}{2}$"#
        label.text = source
        label.setSelectedRange(NSRange(location: 0, length: label.string.utf16.count))
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        pasteboard.declareTypes([.string], owner: nil)
        #expect(label.writeSelection(to: pasteboard, type: .string))
        #expect(pasteboard.string(forType: .string) == source)

        let container = NSTextContainer(containerSize: NSSize(width: 100, height: CGFloat.greatestFiniteMagnitude))
        let layout = NSLayoutManager()
        let storage = NSTextStorage(attributedString: renderer.render(#"$$x_1+x_2+x_3+x_4+x_5+x_6+x_7+x_8$$"#))
        layout.addTextContainer(container)
        storage.addLayoutManager(layout)
        layout.ensureLayout(for: container)
        #expect(layout.usedRect(for: container).width <= 100)
    }

    // MARK: Private

    private let baseSize: CGFloat = 14

    private var renderer: MarkdownRenderer {
        MarkdownRenderer(
            baseFont: .systemFont(ofSize: baseSize),
            foregroundColor: .labelColor,
            lineSpacing: 4,
            paragraphSpacing: 0
        )
    }
}
