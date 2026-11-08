//
//  TranslationResultLabel.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

/// Explicit paragraph direction and alignment for results, independent of the interface language.
@objc(EZTranslationResultLabel)
final class TranslationResultLabel: MarkdownLabel {
    // MARK: Internal

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
            // Natural alignment can follow the app locale. Resolve content explicitly so
            // a short final Urdu line aligns with the paragraph's right edge.
            let direction = isCode ? NSWritingDirection.leftToRight : Self.writingDirection(
                in: text,
                range: paragraphRange
            )
            style.alignment = direction == .rightToLeft ? .right : .left
            style.baseWritingDirection = direction
            textStorage.addAttribute(.paragraphStyle, value: style, range: paragraphRange)
        }
        textStorage.endEditing()
    }

    // MARK: Private

    // Unicode bidi classes skip neutral punctuation and numbers, including list markers.
    private static let firstStrongCharacter = try! NSRegularExpression(
        pattern: #"(?<rtl>[\p{bc=R}\p{bc=AL}])|\p{bc=L}"#
    )

    private static func writingDirection(in text: NSString, range: NSRange) -> NSWritingDirection {
        guard let match = firstStrongCharacter.firstMatch(in: text as String, range: range) else {
            return .leftToRight
        }
        return match.range(withName: "rtl").location != NSNotFound ? .rightToLeft : .leftToRight
    }
}
