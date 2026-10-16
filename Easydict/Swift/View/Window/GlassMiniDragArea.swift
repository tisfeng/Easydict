//
//  GlassMiniDragArea.swift
//  Easydict
//

import AppKit
import SwiftUI

/// The top inset remains draggable even when the text view consumes mouse events or the panel is pinned.
struct GlassMiniDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        DragView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
