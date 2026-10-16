//
//  GlassMiniTextView.swift
//  Easydict
//

import AppKit
import SwiftUI

/// Selectable text with an unobtrusive overlay scroller, independent of the system's legacy scrollbar setting.
struct GlassMiniTextView: NSViewRepresentable {
    let text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScroller = GlassMiniScroller()
        scrollView.verticalScroller?.controlSize = .mini
        scrollView.focusRingType = .none

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.focusRingType = .none
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.containerSize = NSSize(width: 1, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView, textView.string != text else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]))
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}

/// Retains AppKit scrolling, thumb dragging and automatic fading while drawing only a thin thumb.
private final class GlassMiniScroller: NSScroller {
    override static var isCompatibleWithOverlayScrollers: Bool { true }

    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {}

    override func drawKnob() {
        let knob = rect(for: .knob)
        let thinKnob = NSRect(x: knob.midX - 1.5, y: knob.minY, width: 3, height: knob.height)
        NSColor.labelColor.withAlphaComponent(0.3).setFill()
        NSBezierPath(roundedRect: thinKnob, xRadius: 1.5, yRadius: 1.5).fill()
    }
}
