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

    init(screen: NSScreen, onImageCaptured: @escaping (NSImage?) -> ()) {
        self.onImageCaptured = onImageCaptured
        self.screen = screen
        let screenBounds = getBounds(of: screen.frame)
        self._backgroundImage = State(initialValue: takeScreenshot(of: screenBounds, in: screen))

        // Load last screenshot area from UserDefaults
        let lastRect = Screenshot.shared.lastScreenshotRect
        self._savedRect = State(initialValue: lastRect)
        self._showTip = State(initialValue: !lastRect.isEmpty)

//        updateMouseLocation(NSEvent.mouseLocation)
    }

    // MARK: Internal

    var body: some View {
        ZStack {
            backgroundLayer
            selectionLayer

            // Show last screenshot area tip if available
            if showTip {
                tipLayer
            }
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
    @State private var monitors: [Any] = [] // Single array to store all event monitors
    @State private var savedRect: CGRect
    @State private var showTip: Bool
    @State private var isShowingPreview = false
    @State private var previewTimer: Timer?

    /// Screen frame is `bottom-left` origin.
    private let screen: NSScreen
    private let onImageCaptured: (NSImage?) -> ()

    @State private var isMouseInCurrentScreen = true {
        didSet {
//            NSLog("didSet isMouseInCurrentScreen: \(isMouseInCurrentScreen)")
        }
    }

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
                    .opacity(0.2)

                // Dark mask when selecting, turn to transparent when mouse moving AND mouse is in current screen
                Rectangle()
                    .fill(Color.black.opacity(isMouseMoved && isMouseInCurrentScreen ? 0 : 0.4))
                    .ignoresSafeArea()
                    .animation(.easeOut, value: isMouseMoved && isMouseInCurrentScreen)
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
                .animation(isShowingPreview ? .easeInOut : nil, value: selectedRect)

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

    /// Tip layer at the bottom-left
    private var tipLayer: some View {
        VStack {
            Spacer()
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("screenshot.tip.click_d_to_capture_last_area")
                        .foregroundStyle(.white)

                    Divider()

                    Text("screenshot.tip.escape_to_cancel_capture")
                        .foregroundStyle(.white)
                }
                .fixedSize(horizontal: true, vertical: false)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.black.opacity(0.8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 5)
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                        }
                }

                Spacer()
            }
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

        selectedRect = CGRect(origin: origin, size: size).integral
        isSelecting = true
        isMouseMoved = true
    }

    /// Handle drag gesture end
    private func handleDragEnd(_ value: DragGesture.Value? = nil) {
        isMouseMoved = true

        var rectToCapture = selectedRect

        // If triggered by D keyboard shortcut (no value), use saved area as selected rect
        if value == nil, !savedRect.isEmpty {
            NSLog("Using saved rect: \(savedRect)")

            rectToCapture = savedRect

            // Adjust saved rect to fit current screen
//            rectToCapture = adjusLasttScreenshotRect(
//                lastRect: savedRect,
//                lastScreenFrame: Screenshot.shared.lastScreenFrame,
//                currentScreenFrame: screen.frame
//            )
//            NSLog("Adjusted rect to fit screen: \(rectToCapture)")

            showPreviewForRect(rectToCapture, in: Screenshot.shared.lastScreen)
        } else {
            NSLog("Selected rect: \(selectedRect)")

            if rectToCapture.width > 10, rectToCapture.height > 10 {
                // Save screenshot area to UserDefaults
                Screenshot.shared.lastScreenshotRect = rectToCapture
                Screenshot.shared.lastScreen = screen
                onImageCaptured(takeScreenshot(of: rectToCapture, in: screen))
            } else {
                NSLog("Selected rect is too small, ignore")
                onImageCaptured(nil)
            }
        }
    }

    /// Show preview and set delayed callback
    private func showPreviewForRect(_ rect: CGRect, in screen: NSScreen?) {
        // Cancel previous timer
        previewTimer?.invalidate()

        // Set selection rectangle to trigger UI update
        selectedRect = rect
        isSelecting = true
        isShowingPreview = true

        // Call callback after 1.0 second
        previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [self] _ in
            isSelecting = false
            isShowingPreview = false

            if rect.width > 10, rect.height > 10 {
                onImageCaptured(takeScreenshot(of: rect, in: screen))
            } else {
                NSLog("Preview rect is too small, ignore")
                onImageCaptured(nil)
            }
        }
    }

    // MARK: Monitor Setup and Cleanup

    /// Setup all event monitors
    private func setupMonitors() {
        // Add mouse listener to detect mouse movement
        if let mouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { [self] event in
            // Update mouse location and check if it's in current screen
            updateMouseLocation(NSEvent.mouseLocation)
            return event
        }) {
            monitors.append(mouseMonitor)
        }

        // Handle escape key
        let escapeHandler = {
            NSLog("ESC key detected, close window")
            DispatchQueue.main.async { [self] in
                onImageCaptured(nil)
            }
        }

        // Add keyboard listener to detect D key - Only use local monitor for key events
        // This allows us to prevent the D key from being passed to other applications
        if let keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [self] event in
            if event.keyCode == kVK_ANSI_D {
                NSLog("D key pressed, capturing last screenshot area")

                NSLog("Last screen: \(Screenshot.shared.lastScreen?.deviceDescriptionString)")
                NSLog("screen: \(screen.deviceDescriptionString)")

                if savedRect != .zero, screen.isSameScreen(Screenshot.shared.lastScreen) {
                    DispatchQueue.main.async {
                        handleDragEnd(nil)
                    }
                } else {
                    NSLog("No previous screenshot rect available")
                }
            } else if event.keyCode == kVK_Escape {
                escapeHandler()
            }
            return event
        }) {
            monitors.append(keyboardMonitor)
        }
    }

    /// Update mouse location and check if it's in current screen
    private func updateMouseLocation(_ location: NSPoint) {
        // Convert mouse location to screen coordinates if needed
        // NSScreen.frame uses bottom-left origin coordinates
        // NSEvent.mouseLocation uses bottom-left origin coordinates with y=0 at the bottom of main screen

        let mouseInScreen = NSMouseInRect(location, screen.frame, false)

        NSLog("Mouse location: \(location)")
        NSLog("Screen frame: \(screen.frame)")
        NSLog("Mouse in screen using NSMouseInRect: \(mouseInScreen)")

        if isMouseInCurrentScreen != mouseInScreen {
            isMouseInCurrentScreen = mouseInScreen
            NSLog("isInScreen updated: \(isMouseInCurrentScreen), screen frame: \(screen.frame)")
        }

        // If mouse is not in current screen, ignore
        if !isMouseInCurrentScreen {
            return
        }

        if !isMouseMoved {
            isMouseMoved = true
            NSLog("Mouse moved, isMouseMoved: \(isMouseMoved), isInScreen: \(isMouseInCurrentScreen)")
        }
    }

    /// Remove all event monitors
    private func removeMonitors() {
        // Clean up timer
        previewTimer?.invalidate()
        previewTimer = nil

        // Remove all monitors
        for monitor in monitors {
            NSEvent.removeMonitor(monitor)
        }
        monitors.removeAll()
    }
}
