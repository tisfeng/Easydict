//
//  ScreenshotOverlayView.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/11.
//  Copyright © 2025 izual. All rights reserved.
//
import Carbon
import ScreenCaptureKit
import SwiftUI

// MARK: - ScreenshotOverlayView

struct ScreenshotOverlayView: View {
    // MARK: Lifecycle

    init(screenFrame: CGRect, onImageCaptured: @escaping (NSImage?) -> ()) {
        self.onImageCaptured = onImageCaptured
        self.screenFrame = screenFrame
        let screenBounds = getBounds(of: screenFrame)
        self._backgroundImage = State(initialValue: takeScreenshot(of: screenBounds))
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            backgroundLayer
            selectionLayer
        }
        .ignoresSafeArea()
        .onAppear(perform: setupMonitors)
        .onDisappear(perform: removeMonitors)
    }

    // MARK: Private

    // MARK: State Variables

    @State private var selectedRect = CGRect.zero
    @State private var isSelecting = false
    @State private var backgroundImage: NSImage?
    @State private var isMouseMoved = false
    @State private var mouseMonitor: Any?
    @State private var keyboardMonitors: [Any] = []

    /// Screen frame is `bottom-left` origin.
    private let screenFrame: CGRect
    private let onImageCaptured: (NSImage?) -> ()

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
                    .ignoresSafeArea()

                // Dark mask when selecting, turn to transparent when mouse moving
                Rectangle()
                    .fill(Color.black.opacity(isMouseMoved ? 0 : 0.4))
                    .ignoresSafeArea()
                    .animation(.easeOut, value: isMouseMoved)
            }
        }
    }

    /// Selection area and drag gesture handling
    private var selectionLayer: some View {
        GeometryReader { geometry in
            ZStack {
                if isSelecting {
                    selectionRectangle
                }
            }
            .compositingGroup()

            // Gesture recognition layer
            Rectangle()
                .fill(Color.clear)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(drag)
        }
    }

    /// Visual representation of the selection area
    private var selectionRectangle: some View {
        Group {
            // Selection border with semi-transparent background
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .background(Color.black.opacity(0.1))
                .frame(width: selectedRect.width, height: selectedRect.height)
                .position(
                    x: selectedRect.midX,
                    y: selectedRect.midY
                )

            // Clear mask for selection area
            Rectangle()
                .fill(Color.clear)
                .frame(width: selectedRect.width, height: selectedRect.height)
                .position(
                    x: selectedRect.midX,
                    y: selectedRect.midY
                )
                .blendMode(.destinationOut)
        }
    }

    // MARK: Event Handlers

    /// Handle drag gesture change
    private func handleDragChange(_ value: DragGesture.Value) {
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

        selectedRect = CGRect(origin: origin, size: size)
        isSelecting = true
        isMouseMoved = true
    }

    /// Handle drag gesture end
    private func handleDragEnd(_ value: DragGesture.Value) {
        isSelecting = false
        NSLog("Selected rect: \(selectedRect)")

        if selectedRect.width > 10, selectedRect.height > 10 {
            onImageCaptured(takeScreenshot(of: selectedRect))
        } else {
            NSLog("Selected rect is too small, ignore")
            onImageCaptured(nil)
        }
    }

    // MARK: Monitor Setup and Cleanup

    /// Setup all event monitors
    private func setupMonitors() {
        // Setup mouse monitor
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [self] _ in
            if !isMouseMoved {
                DispatchQueue.main.async {
                    isMouseMoved = true
                    NSLog("Mouse moved, isMouseMoved: \(isMouseMoved)")
                }
            }
        }

        // Handle escape key
        let escapeHandler = {
            NSLog("ESC key detected, close window")
            DispatchQueue.main.async {
                onImageCaptured(nil)
            }
        }

        // Setup keyboard monitors (both global and local)
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == kVK_Escape {
                escapeHandler()
            }
        }

        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == kVK_Escape {
                escapeHandler()
                return nil
            }
            return event
        }

        // Save keyboard monitors
        keyboardMonitors = [globalMonitor, localMonitor].compactMap { $0 }

        // Reset mouse movement state
        isMouseMoved = false
    }

    /// Remove all event monitors
    private func removeMonitors() {
        // Remove mouse monitor
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }

        // Remove all keyboard monitors
        for monitor in keyboardMonitors {
            NSEvent.removeMonitor(monitor)
        }
        keyboardMonitors = []
    }
}
