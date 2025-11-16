//
//  ScreenshotOverlayView.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/11.
//  Copyright © 2025 izual. All rights reserved.
//

import SwiftUI

// MARK: - ScreenshotOverlayView

struct ScreenshotOverlayView: View {
    // MARK: Lifecycle

    init(state: ScreenshotState) {
        self.state = state
        // Capture background image in autoreleasepool to ensure CGImage is released promptly
        let capturedImage = autoreleasepool {
            state.screen.takeScreenshot()
        }
        self._backgroundImage = State(initialValue: capturedImage)
    }

    // MARK: Internal

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundLayer
            selectionLayer

            if state.isTipVisible {
                tipLayer
            }
        }
        .ignoresSafeArea()
    }

    // MARK: Private

    @State private var backgroundImage: NSImage?
    @ObservedObject private var state: ScreenshotState

    // MARK: Gestures

    /// Drag gesture for selection
    private var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged(handleDragChange)
            .onEnded(handleDragEnd)
    }

    // MARK: View Components

    /// Background screenshot with dark overlay
    private var backgroundLayer: some View {
        Group {
            if let image = backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                Rectangle()
                    .fill(Color.black.opacity(state.shouldHideDarkOverlay ? 0 : 0.3))
                    .animation(.easeInOut, value: state.shouldHideDarkOverlay)
            }
        }
    }

    /// Selection area and drag gesture handling
    private var selectionLayer: some View {
        GeometryReader { geometry in
            ZStack {
                if !state.selectedRect.isEmpty {
                    selectionRectangleView
                }
            }

            // Gesture recognition layer
            Rectangle()
                .fill(Color.clear)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(drag)
        }
    }

    /// Visual representation of the selection area
    private var selectionRectangleView: some View {
        Group {
            // Selection border with semi-transparent dark background
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .background(Color.black.opacity(0.1)) // Add a darker overlay for selection area
                .frame(width: state.selectedRect.width, height: state.selectedRect.height)
                .position(
                    x: state.selectedRect.midX,
                    y: state.selectedRect.midY
                )
        }
    }

    /// Tip layer at bottom-left corner
    private var tipLayer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("screenshot.tip.capture_last_area_desc")
                .foregroundStyle(.white)

            Divider()

            Text("screenshot.tip.cancel_capture_desc")
                .foregroundStyle(.white)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background {
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black.opacity(0.8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    }
                    // Get the tip frame
                    .onAppear {
                        state.tipFrame = CGRect(
                            x: state.screen.frame.minX,
                            y: state.screen.frame.minY,
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                    }
            }
        }
    }

    // MARK: Event Handlers

    /// Handle drag gesture change
    private func handleDragChange(_ value: DragGesture.Value) {
        // Cancel any pending preview screenshot if user starts dragging
        Screenshot.shared.cancelPreviewScreenshotTimer()

        let adjustedStartLocation = CGPoint(
            x: value.startLocation.x,
            y: value.startLocation.y
        )
        let adjustedLocation = CGPoint(
            x: value.location.x,
            y: value.location.y
        )

        // Calculate selection rectangle
        let origin = CGPoint(
            x: min(adjustedStartLocation.x, adjustedLocation.x),
            y: min(adjustedStartLocation.y, adjustedLocation.y)
        )
        let size = CGSize(
            width: abs(adjustedLocation.x - adjustedStartLocation.x),
            height: abs(adjustedLocation.y - adjustedStartLocation.y)
        )

        state.selectedRect = CGRect(origin: origin, size: size).integral
        state.isTipVisible = false
    }

    /// Handle drag gesture end
    private func handleDragEnd(_ value: DragGesture.Value? = nil) {
        // Cancel any pending preview screenshot (might be redundant here but safe)
        Screenshot.shared.cancelPreviewScreenshotTimer()

        state.isTipVisible = false

        let selectedRect = state.selectedRect
        NSLog("Drag ended, selected rect: \(selectedRect)")

        // Check if selection meets minimum size requirements
        if selectedRect.width > 10, selectedRect.height > 10 {
            // Call the centralized screenshot method
            Screenshot.shared.performScreenshot(screen: state.screen, rect: selectedRect)
        } else {
            NSLog("Screenshot cancelled - Selection too small (minimum: 10x10)")
            // Cancel the screenshot process directly
            Screenshot.shared.finishCapture(nil)
        }
    }
}
