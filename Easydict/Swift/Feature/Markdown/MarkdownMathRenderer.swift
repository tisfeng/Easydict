//
//  MarkdownMathRenderer.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SwiftMath

// MARK: - MarkdownMathRenderer

/// Typesets completed formulas once and keeps a bounded cache across streaming updates.
enum MarkdownMathRenderer {
    // MARK: Internal

    static func render(
        latex: String,
        source: String,
        font: NSFont,
        color: NSColor,
        display: Bool
    )
        -> NSAttributedString? {
        lock.lock()
        defer { lock.unlock() }
        guard !latex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let rgb = color.usingColorSpace(.deviceRGB) else { return nil }
        let key =
            "\(display)|\(font.pointSize)|\(rgb.redComponent),\(rgb.greenComponent),\(rgb.blueComponent),\(rgb.alphaComponent)|\(latex)" as NSString
        let formula: Formula
        if let cached = cache.object(forKey: key) {
            formula = cached
        } else {
            var renderer = MathImage(
                latex: normalizedEnvironments(latex),
                fontSize: font.pointSize,
                textColor: rgb,
                labelMode: display ? .display : .text
            )
            let (error, image, layout) = renderer.asImage()
            guard error == nil, let image, let layout,
                  image.size.width.isFinite, image.size.height.isFinite,
                  image.size.width > 0, image.size.height > 0 else { return nil }
            image.accessibilityDescription = latex
            formula = Formula(image: image, descent: layout.descent)
            cache.setObject(formula, forKey: key)
        }
        let attachment = MarkdownMathAttachment()
        attachment.image = formula.image
        attachment.bounds = NSRect(
            x: 0,
            y: -formula.descent,
            width: formula.image.size.width,
            height: formula.image.size.height
        )
        let result = NSMutableAttributedString(attachment: attachment)
        result.addAttribute(.markdownMathSource, value: source, range: NSRange(location: 0, length: result.length))
        return result
    }

    // MARK: Private

    private final class Formula: NSObject {
        // MARK: Lifecycle

        init(image: NSImage, descent: CGFloat) { self.image = image; self.descent = descent }

        // MARK: Internal

        let image: NSImage
        let descent: CGFloat
    }

    private static let lock = NSLock()
    private static let cache: NSCache<NSString, Formula> = {
        let cache = NSCache<NSString, Formula>()
        cache.countLimit = 256
        return cache
    }()

    /// SwiftMath's aligned/gather environments provide the unnumbered layout used in result cards.
    private static func normalizedEnvironments(_ latex: String) -> String {
        var result = latex
        for (environment, replacement) in [
            ("align", "aligned"), ("align*", "aligned"), ("gather*", "gather"),
            ("equation", ""), ("equation*", ""),
        ] {
            for boundary in ["begin", "end"] {
                result = result.replacingOccurrences(
                    of: "\\\(boundary){\(environment)}",
                    with: replacement.isEmpty ? "" : "\\\(boundary){\(replacement)}"
                )
            }
        }
        return result
    }
}

// MARK: - MarkdownMathAttachment

/// Fits wide equations into the text container without changing the original image.
private final class MarkdownMathAttachment: NSTextAttachment {
    override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: NSRect,
        glyphPosition position: NSPoint,
        characterIndex charIndex: Int
    )
        -> NSRect {
        let width = max(1, lineFrag.width - (textContainer?.lineFragmentPadding ?? 0) * 2)
        let scale = min(1, width / max(1, bounds.width))
        return NSRect(x: 0, y: bounds.minY * scale, width: bounds.width * scale, height: bounds.height * scale)
    }
}

extension NSAttributedString.Key {
    static let markdownMathSource = NSAttributedString.Key("EDMarkdownMathSource")
}
