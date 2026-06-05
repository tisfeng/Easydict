//
//  MarkdownRendererTests.swift
//  EasydictTests
//
//  Created by Lin on 2026/4/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Testing

@testable import Easydict

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
