//
//  ScreenshotTranslationOverlayView.swift
//  Easydict
//
//  Created by bsythegreat on 2026/7/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SFSafeSymbols
import SwiftUI

// MARK: - ScreenshotTranslationOverlayView

/// Renders translated labels and provides pan and zoom interaction for side-by-side results.
struct ScreenshotTranslationOverlayView: View {
    // MARK: Internal

    let content: ScreenshotTranslationContent
    let mode: ScreenshotTranslateDisplayMode
    let close: () -> ()

    var body: some View {
        ZStack(alignment: .topLeading) {
            if mode == .imageSideBySide {
                sideBySideContent
            } else {
                ScreenshotTranslationCanvas(content: content)
            }

            Button(action: close) {
                Image(systemSymbol: .xmarkCircleFill)
                    .font(.system(size: 20))
                    .foregroundStyle(.white, .black.opacity(0.65))
            }
            .buttonStyle(.plain)
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        }
    }

    // MARK: Private

    private var sideBySideContent: some View {
        ScreenshotTranslationZoomView(content: content)
    }
}

// MARK: - ScreenshotTranslationZoomView

/// Wraps the side-by-side result in a native scroll view for cursor-anchored trackpad zooming.
private struct ScreenshotTranslationZoomView: NSViewRepresentable {
    let content: ScreenshotTranslationContent

    func makeNSView(context: Context) -> ScreenshotTranslationScrollView {
        ScreenshotTranslationScrollView(content: content)
    }

    func updateNSView(_ scrollView: ScreenshotTranslationScrollView, context: Context) {
        scrollView.update(content)
    }
}

// MARK: - ScreenshotTranslationScrollView

/// Provides native pinch-to-zoom and two-finger panning while keeping the pointer as zoom anchor.
private final class ScreenshotTranslationScrollView: NSScrollView {
    // MARK: Lifecycle

    init(content: ScreenshotTranslationContent) {
        self.hostingView = NSHostingView(rootView: ScreenshotTranslationCanvas(content: content))
        super.init(frame: .zero)

        allowsMagnification = true
        minMagnification = 1
        maxMagnification = 4
        magnification = 1
        drawsBackground = false
        hasHorizontalScroller = false
        hasVerticalScroller = false
        autohidesScrollers = true
        documentView = hostingView

        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(resetZoom(_:)))
        doubleClick.numberOfClicksRequired = 2
        addGestureRecognizer(doubleClick)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func layout() {
        super.layout()
        hostingView.frame = CGRect(origin: .zero, size: contentSize)
    }

    func update(_ content: ScreenshotTranslationContent) {
        hostingView.rootView = ScreenshotTranslationCanvas(content: content)
    }

    // MARK: Private

    private let hostingView: NSHostingView<ScreenshotTranslationCanvas>

    @objc
    private func resetZoom(_ recognizer: NSClickGestureRecognizer) {
        let point = hostingView.convert(recognizer.location(in: self), from: self)
        setMagnification(1, centeredAt: point)
    }
}

// MARK: - ScreenshotTranslationCanvas

/// Draws a translated screenshot at any size while preserving OCR bounding-box positions.
private struct ScreenshotTranslationCanvas: View {
    // MARK: Internal

    let content: ScreenshotTranslationContent

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image(nsImage: content.image)
                    .resizable()
                    .frame(width: geometry.size.width, height: geometry.size.height)

                ForEach(content.items) { item in
                    let rect = displayRect(item.boundingBox, in: geometry.size)
                    Text(item.text)
                        .font(.system(size: max(11, min(rect.height * 0.72, 28))))
                        .lineLimit(nil)
                        .minimumScaleFactor(0.35)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .frame(
                            width: max(rect.width, 24),
                            height: max(rect.height, 18),
                            alignment: .leading
                        )
                        .background {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.regularMaterial)
                        }
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
    }

    // MARK: Private

    private func displayRect(_ visionRect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: visionRect.minX * size.width,
            y: (1 - visionRect.maxY) * size.height,
            width: visionRect.width * size.width,
            height: visionRect.height * size.height
        )
    }
}
