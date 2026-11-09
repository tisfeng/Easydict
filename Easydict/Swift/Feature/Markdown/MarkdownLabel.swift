//
//  MarkdownLabel.swift
//  Easydict
//
//  Created by Lin on 2026/4/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

/// Displays Markdown or plain text using the label's font and appearance.
@objc(EDMarkdownLabel)
class MarkdownLabel: EZLabel {
    // MARK: Internal

    /// Re-renders the current text when Markdown is enabled or disabled.
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

        // EZLabel's style setters can call this before text is initialized.
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

    override func copy(_ sender: Any?) {
        guard markdownEnabled, let textStorage,
              selectedRanges.contains(where: { selection in
                  let range = selection.rangeValue
                  guard range.length > 0, NSMaxRange(range) <= textStorage.length else { return false }
                  var containsMath = false
                  textStorage.enumerateAttribute(.markdownMathSource, in: range) { source, _, stop in
                      if source != nil {
                          containsMath = true
                          stop.pointee = true
                      }
                  }
                  return containsMath
              }) else {
            super.copy(sender)
            return
        }

        // AppKit's Copy action can bypass the single-type pasteboard writer.
        _ = writeSelection(to: .general, types: [.string])
    }

    /// Include TeX source when a selection containing rendered equations is copied as text.
    override func writeSelection(to pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        guard markdownEnabled, type == .string else {
            return super.writeSelection(to: pboard, type: type)
        }
        let selections = selectedRanges.compactMap { sourceText(in: $0.rangeValue) }
        guard !selections.isEmpty else { return false }
        return pboard.setString(selections.joined(separator: "\n"), forType: .string)
    }

    override func selectedText() -> String? {
        guard markdownEnabled, let range = selectedRanges.first?.rangeValue, range.length > 0 else {
            return super.selectedText()
        }
        return sourceText(in: range)
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

    /// Expands mathematical attachments back to their original TeX for text actions.
    private func sourceText(in range: NSRange) -> String? {
        guard let textStorage, range.length > 0, NSMaxRange(range) <= textStorage.length else { return nil }
        let selected = textStorage.attributedSubstring(from: range)
        let plain = NSMutableString(string: "")
        // Enumerate attachment runs separately, even when adjacent formulas have the same source.
        selected.enumerateAttributes(in: NSRange(
            location: 0,
            length: selected.length
        )) { attributes, range, _ in
            plain
                .append(attributes[.markdownMathSource] as? String ?? (selected.string as NSString)
                    .substring(with: range))
        }
        return plain as String
    }
}


/// Displays the screenshot transcript while letting typing and paste start a text query.
@objc(EDScreenshotSourceLabel)
final class ScreenshotSourceLabel: MarkdownLabel {
    @objc var beginEditing: (() -> NSTextView?)?

    override func keyDown(with event: NSEvent) {
        let hasText = event.characters?.unicodeScalars.contains {
            !CharacterSet.controlCharacters.contains($0) && !(0xF700 ... 0xF8FF).contains($0.value)
        } ?? false
        guard hasText, event.modifierFlags.intersection([.command, .control]).isEmpty,
              let editor = beginEditing?() else {
            super.keyDown(with: event)
            return
        }
        editor.keyDown(with: event)
    }

    override func paste(_ sender: Any?) {
        guard let editor = beginEditing?() else { return }
        editor.paste(sender)
    }

    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(paste(_:)) {
            return beginEditing != nil && NSPasteboard.general.availableType(from: [.string]) != nil
        }
        return super.validateUserInterfaceItem(item)
    }
}
