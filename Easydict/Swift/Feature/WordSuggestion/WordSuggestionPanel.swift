//
//  WordSuggestionPanel.swift
//  Easydict
//
//  Created by Anson on 2026/11/20.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

// MARK: - WordSuggestionPanel

/// Borderless child window that shows the suggestion rows under the query input.
///
/// It never becomes key, so typing continues in the query text view while the
/// list is open; keyboard navigation is forwarded by `WordSuggestionController`.
final class WordSuggestionPanel: NSPanel {
    // MARK: Lifecycle

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        becomesKeyOnlyIfNeeded = true
        contentView = listView
    }

    // MARK: Internal

    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }

    let listView = WordSuggestionListView()
}

// MARK: - WordSuggestionListView

/// Rows plus a keyboard hint footer, drawn on a menu-style background.
final class WordSuggestionListView: NSVisualEffectView {
    // MARK: Lifecycle

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        material = .menu
        state = .active
        blendingMode = .behindWindow
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true

        footerSeparator.boxType = .separator
        footerLabel.textColor = .tertiaryLabelColor
        addSubview(footerSeparator)
        addSubview(footerLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override var isFlipped: Bool {
        true
    }

    /// Called with the row index the user clicked.
    var onClick: ((Int) -> ())?

    /// Called with the row index under the mouse.
    var onHover: ((Int) -> ())?

    /// Called with the row index the mouse left.
    var onHoverEnd: ((Int) -> ())?

    var fontSizeRatio: CGFloat = 1

    var suggestions: [WordSuggestion] = [] {
        didSet { rebuildRows() }
    }

    /// Highlighted row, or `-1` for none.
    var selectedIndex = -1 {
        didSet { updateSelection() }
    }

    /// Height needed to show every row and the footer.
    var preferredHeight: CGFloat {
        verticalPadding * 2 + CGFloat(rows.count) * rowHeight + footerHeight
    }

    override func layout() {
        super.layout()
        var y = verticalPadding
        for row in rows {
            row.frame = NSRect(x: 0, y: y, width: bounds.width, height: rowHeight)
            y += rowHeight
        }
        footerSeparator.frame = NSRect(x: 0, y: y + 2, width: bounds.width, height: 1)
        footerLabel.sizeToFit()
        footerLabel.frame.origin = NSPoint(
            x: horizontalPadding,
            y: y + (footerHeight - footerLabel.frame.height) / 2 + 2
        )
    }

    // MARK: Private

    private let cornerRadius: CGFloat = 8
    private let verticalPadding: CGFloat = 4
    private let horizontalPadding: CGFloat = 14
    private let footerSeparator = NSBox()
    private let footerLabel = NSTextField(labelWithString: "")

    private var rows: [WordSuggestionRowView] = []

    private var rowHeight: CGFloat {
        (26 * fontSizeRatio).rounded()
    }

    private var footerHeight: CGFloat {
        26
    }

    private func rebuildRows() {
        rows.forEach { $0.removeFromSuperview() }
        footerLabel.font = .systemFont(ofSize: 11)
        // `NSLocalizedString` goes through the main bundle override, so it follows
        // the in-app interface language instead of the system language.
        footerLabel.stringValue = [
            NSLocalizedString("query.word_suggestion.hint.select", comment: ""),
            NSLocalizedString("query.word_suggestion.hint.fill", comment: ""),
            NSLocalizedString("query.word_suggestion.hint.query", comment: ""),
            NSLocalizedString("query.word_suggestion.hint.close", comment: ""),
        ].joined(separator: "     ")
        rows = suggestions.enumerated().map { index, suggestion in
            let row = WordSuggestionRowView(
                suggestion: suggestion,
                fontSize: 13 * fontSizeRatio,
                horizontalPadding: horizontalPadding
            )
            row.onClick = { [weak self] in self?.onClick?(index) }
            row.onHover = { [weak self] in self?.onHover?(index) }
            row.onHoverEnd = { [weak self] in self?.onHoverEnd?(index) }
            addSubview(row)
            return row
        }
        updateSelection()
        needsLayout = true
    }

    private func updateSelection() {
        for (index, row) in rows.enumerated() {
            row.isSelected = index == selectedIndex
        }
    }
}

// MARK: - WordSuggestionRowView

/// One `word pos meaning` line with a fixed gap between parts; the meaning is truncated to fit.
final class WordSuggestionRowView: NSView {
    // MARK: Lifecycle

    init(suggestion: WordSuggestion, fontSize: CGFloat, horizontalPadding: CGFloat) {
        self.suggestion = suggestion
        self.fontSize = fontSize
        self.horizontalPadding = horizontalPadding
        super.init(frame: .zero)

        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.cell?.truncatesLastVisibleLine = true
        addSubview(label)
        updateText()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override var isFlipped: Bool {
        true
    }

    var onClick: (() -> ())?
    var onHover: (() -> ())?
    var onHoverEnd: (() -> ())?

    var isSelected = false {
        didSet { updateText() }
    }

    override func layout() {
        super.layout()
        highlightFrame = bounds.insetBy(dx: 6, dy: 1)
        let height = label.intrinsicContentSize.height
        label.frame = NSRect(
            x: horizontalPadding,
            y: (bounds.height - height) / 2,
            width: max(bounds.width - horizontalPadding * 2, 0),
            height: height
        )
    }

    override func draw(_ dirtyRect: NSRect) {
        guard isSelected else { return }
        NSColor.selectedContentBackgroundColor.setFill()
        NSBezierPath(roundedRect: highlightFrame, xRadius: 5, yRadius: 5).fill()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        onHover?()
    }

    override func mouseExited(with event: NSEvent) {
        onHoverEnd?()
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    // MARK: Private

    /// Extra spacing added to the space between parts, for a gap of roughly 10 pt.
    private let gapKern: CGFloat = 6

    private let suggestion: WordSuggestion
    private let fontSize: CGFloat
    private let horizontalPadding: CGFloat
    private let label = NSTextField(labelWithString: "")
    private var highlightFrame: NSRect = .zero

    private func updateText() {
        let primary: NSColor = isSelected ? .alternateSelectedControlTextColor : .labelColor
        let secondary: NSColor = isSelected ? .alternateSelectedControlTextColor : .secondaryLabelColor

        let text = NSMutableAttributedString()
        if suggestion.matchedOffsets.isEmpty {
            text.append(NSAttributedString(string: suggestion.word, attributes: [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .medium),
                .foregroundColor: primary,
            ]))
        } else {
            // Letters that match the typed text are bold, the rest regular: `inves` in `investment`.
            for (offset, character) in suggestion.word.enumerated() {
                let isMatched = suggestion.matchedOffsets.contains(offset)
                text.append(NSAttributedString(string: String(character), attributes: [
                    .font: NSFont.systemFont(ofSize: fontSize, weight: isMatched ? .bold : .regular),
                    .foregroundColor: primary,
                ]))
            }
        }
        let parts: [(String?, NSFont)] = [
            (suggestion.partOfSpeech, .systemFont(ofSize: fontSize - 2)),
            (suggestion.meaning, .systemFont(ofSize: fontSize)),
        ]
        for case let (part?, font) in parts where !part.isEmpty {
            text.append(NSAttributedString(string: " ", attributes: [.font: font, .kern: gapKern]))
            text.append(NSAttributedString(string: part, attributes: [
                .font: font,
                .foregroundColor: secondary,
            ]))
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        text.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: text.length))
        label.attributedStringValue = text
        needsDisplay = true
    }
}
