//
//  MarkdownLabel.swift
//  Easydict
//
//  Created by Lin on 2026/4/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

/// `EZLabel` subclass that renders Markdown source through ``MarkdownRenderer``
/// when `markdownEnabled` is `true`. Falls back to the parent's plain-text
/// pipeline otherwise so non-AI services keep their existing appearance and
/// dark-mode switching keeps working through the inherited appearance hook.
@objc(EDMarkdownLabel)
final class MarkdownLabel: EZLabel {
    // MARK: Internal

    /// Toggles between Markdown rendering and plain-text rendering. Re-applies
    /// the current `text` immediately so the visible state stays consistent.
    @objc var markdownEnabled: Bool = true {
        didSet {
            guard oldValue != markdownEnabled else { return }
            updateDisplayedText()
        }
    }

    override func updateDisplayedText() {
        guard markdownEnabled else {
            super.updateDisplayedText()
            return
        }

        // `text` is `nullable` because EZLabel triggers `updateDisplayedText`
        // from the font / line-spacing setters during super init, before
        // `setText:` has run. Coalesce so an early invocation renders nothing
        // instead of crashing.
        let source = text ?? ""
        guard !source.isEmpty else {
            textStorage?.setAttributedString(NSAttributedString())
            return
        }

        effectiveAppearance.performAsCurrentDrawingAppearance {
            let renderer = MarkdownRenderer(
                baseFont: font ?? .systemFont(ofSize: 14),
                foregroundColor: resolvedForegroundColor,
                lineSpacing: lineSpacing,
                paragraphSpacing: paragraphSpacing
            )
            textStorage?.setAttributedString(renderer.render(source))
        }
        needsDisplay = true
    }

    /// Include TeX source when a selection containing rendered equations is copied as text.
    override func writeSelection(to pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        guard markdownEnabled, type == .string, let textStorage else {
            return super.writeSelection(to: pboard, type: type)
        }
        let selections = selectedRanges.compactMap { value -> String? in
            let range = value.rangeValue
            guard range.length > 0, NSMaxRange(range) <= textStorage.length else { return nil }
            let selected = textStorage.attributedSubstring(from: range)
            let plain = NSMutableString(string: "")
            selected.enumerateAttribute(.markdownMathSource, in: NSRange(
                location: 0,
                length: selected.length
            )) { source, range, _ in
                plain.append(source as? String ?? (selected.string as NSString).substring(with: range))
            }
            return plain as String
        }
        guard !selections.isEmpty else { return false }
        return pboard.setString(selections.joined(separator: "\n"), forType: .string)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard markdownEnabled, let layoutManager, let textContainer, let textStorage,
              textStorage.length > 0 else { return }
        let origin = textContainerOrigin
        let glyphs = layoutManager.glyphRange(for: textContainer)
        NSColor.separatorColor.setFill()
        layoutManager.enumerateLineFragments(forGlyphRange: glyphs) { rect, used, _, range, _ in
            let characters = layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: nil)
            guard characters.location < textStorage.length else { return }
            let attrs = textStorage.attributes(at: characters.location, effectiveRange: nil)
            if let indents = attrs[.markdownBlockquote] as? [CGFloat] {
                for indent in indents {
                    NSBezierPath(roundedRect: NSRect(
                        x: origin.x + indent + 2,
                        y: origin.y + rect.minY,
                        width: 2,
                        height: rect.height
                    ), xRadius: 1, yRadius: 1).fill()
                }
            }
            if attrs[.markdownRule] as? Bool == true {
                NSRect(
                    x: origin.x + used.minX,
                    y: origin.y + rect.midY,
                    width: max(0, rect.width - used.minX),
                    height: 1
                ).fill()
            }
        }
    }

    // MARK: Private

    private var resolvedForegroundColor: NSColor {
        if let textForegroundColor { return textForegroundColor }
        return isDarkMode ? .ez_resultTextDark() : .ez_resultTextLight()
    }
}
