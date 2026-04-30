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

        let source = text
        guard !source.isEmpty else {
            textStorage?.setAttributedString(NSAttributedString())
            return
        }

        let renderer = MarkdownRenderer(
            baseFont: font ?? .systemFont(ofSize: 14),
            foregroundColor: resolvedForegroundColor,
            lineSpacing: lineSpacing,
            paragraphSpacing: paragraphSpacing
        )
        let attributed = renderer.render(source)
        textStorage?.setAttributedString(attributed)
    }

    // MARK: Private

    private var resolvedForegroundColor: NSColor {
        if let textForegroundColor { return textForegroundColor }
        return isDarkMode ? .ez_resultTextDark() : .ez_resultTextLight()
    }
}
