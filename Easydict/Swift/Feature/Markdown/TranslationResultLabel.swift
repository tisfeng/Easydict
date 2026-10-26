//
//  TranslationResultLabel.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

/// Paragraph direction for translation results, independent of the interface language.
@objc(EZTranslationResultLabel)
final class TranslationResultLabel: MarkdownLabel {
    override func updateDisplayedText() {
        super.updateDisplayedText()
        guard let textStorage, textStorage.length > 0 else { return }

        // Work from a snapshot so paragraph edits preserve all inline rendering attributes.
        let rendered = NSAttributedString(attributedString: textStorage)
        let text = rendered.string as NSString
        textStorage.beginEditing()
        text.enumerateSubstrings(
            in: NSRange(location: 0, length: text.length),
            options: [.byParagraphs, .substringNotRequired]
        ) { _, _, paragraphRange, _ in
            let original = rendered.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil)
                as? NSParagraphStyle ?? .default
            let style = original.mutableCopy() as! NSMutableParagraphStyle
            let isCode = rendered.attribute(.markdownCodeBlock, at: paragraphRange.location, effectiveRange: nil)
                as? Bool ?? false
            style.alignment = isCode ? .left : .natural
            style.baseWritingDirection = isCode ? .leftToRight : .natural
            textStorage.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
        }
        textStorage.endEditing()
    }
}
