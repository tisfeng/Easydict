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
    @State private var backgroundImage: NSImage?
    @State private var isMouseMoved = false
    @State private var isMouseInCurrentScreen = false
    @State private var monitors: [Any] = [] // Single array to store all event monitors
    @State private var savedRect: CGRect
    @State private var showTip: Bool
    @State private var isShowingPreview = false
    @State private var previewTimer: Timer?

    /// Screen frame is `bottom-left` origin.
    private let screen: NSScreen
    private let onImageCaptured: (NSImage?) -> ()

    private var hideDarkOverlay: Bool {
        isMouseMoved && isMouseInCurrentScreen || isShowingPreview
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

                // Dark mask when selecting, turn to transparent when mouse moving AND mouse is in current screen
                Rectangle()
                    .fill(Color.black.opacity(hideDarkOverlay ? 0 : 0.4))
                    .ignoresSafeArea()
                    .animation(.easeOut, value: hideDarkOverlay)
            }
        }
    }

    /// Selection area and drag gesture handling
    private var selectionLayer: some View {
        GeometryReader { geometry in
            ZStack {
                if !selectedRect.isEmpty {
                    selectionRectangleView
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
    private var selectionRectangleView: some View {
        Group {
            // Selection border with semi-transparent dark background
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .background(Color.black.opacity(0.1)) // Add a darker overlay for selection area
                .frame(width: selectedRect.width, height: selectedRect.height)
                .position(
                    x: selectedRect.midX,
                    y: selectedRect.midY
                )
                .animation(isShowingPreview ? .easeInOut : nil, value: selectedRect)
        }
    }

    /// Tip layer at bottom-left corner
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
        isMouseMoved = true
    }

    /// Handle drag gesture end
    private func handleDragEnd(_ value: DragGesture.Value? = nil) {
        isMouseMoved = true

        var rectToCapture = selectedRect

        // If triggered by D key shortcut (no value), use saved area as selected rect
        if value == nil, !savedRect.isEmpty {
            NSLog("Using saved rect: \(savedRect)")

            rectToCapture = savedRect
            showPreviewForRect(rectToCapture, in: Screenshot.shared.lastScreen)
        } else {
            selectedRect = .zero

            NSLog("Selected rect: \(selectedRect)")

            if rectToCapture.width > 10, rectToCapture.height > 10 {
                // Save screenshot area to UserDefaults
                Screenshot.shared.lastScreenshotRect = rectToCapture
                Screenshot.shared.lastScreen = screen

                asyncTakeScreenshot(of: rectToCapture, in: screen) { image in
                    onImageCaptured(image)
                }

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

        var rectToCapture = rect
        let targetScreen = screen ?? self.screen

        // If the target screen is nil, adjust rect to fit current screen
        if screen == nil {
            rectToCapture = adjusLastScreenshotRect(
                lastRect: rectToCapture, currentScreenFrame: targetScreen.frame
            )
        }

        // Set selection rectangle to trigger UI update
        selectedRect = rectToCapture
        isShowingPreview = true

        // Call callback after 1.0 second
        previewTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [self] _ in
            if rectToCapture.width > 10, rectToCapture.height > 10 {
                selectedRect = .zero

                asyncTakeScreenshot(of: rectToCapture, in: targetScreen) { image in
                    onImageCaptured(image)
                }
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
        if let mouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .mouseMoved,
            handler: { [self] event in
                // NSEvent.mouseLocation is `bottom-left` origin, the same as screen frame.
                updateMouseLocation(NSEvent.mouseLocation)
                return event
            }
        ) {
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
        if let keyboardMonitor = NSEvent.addLocalMonitorForEvents(
            matching: .keyDown,
            handler: { [self] event in
                if event.keyCode == kVK_ANSI_D {
                    NSLog("D key pressed, capturing last screenshot area")

                    isMouseInCurrentScreen = screen.frame.contains(NSEvent.mouseLocation)

                    let lastScreen = Screenshot.shared.lastScreen
                    NSLog("Last screen: \(lastScreen?.deviceDescriptionString ?? "")")
                    NSLog("Current screen: \(screen.deviceDescriptionString)")
                    NSLog("Is mouse in current screen: \(isMouseInCurrentScreen)")

                    let isRightScreen =
                        screen.isSameScreen(lastScreen)
                            || (lastScreen == nil && isMouseInCurrentScreen)
                    if !savedRect.isEmpty, isRightScreen {
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
            }
        ) {
            monitors.append(keyboardMonitor)
        }
    }

    /// Update mouse location and check if it's in current screen
    private func updateMouseLocation(_ location: NSPoint) {
        let mouseInScreen = screen.frame.contains(location)

        if isMouseInCurrentScreen != mouseInScreen {
            isMouseInCurrentScreen = mouseInScreen
            NSLog("isInScreen updated: \(isMouseInCurrentScreen)")
        }

        // If mouse is not in current screen, ignore
        if !isMouseInCurrentScreen {
            return
        }

        if !isMouseMoved {
            isMouseMoved = true
            NSLog(
                "Mouse moved, isMouseMoved: \(isMouseMoved), isInScreen: \(isMouseInCurrentScreen)"
            )
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

    /// Take screenshot of the screen area asynchronously
    private func asyncTakeScreenshot(
        of rect: CGRect,
        in screen: NSScreen?,
        completion: @escaping (NSImage?) -> ()
    ) {
        // Hide selection rectangle, avoid capturing it
        selectedRect = .zero

        // async to wait for UI update
        DispatchQueue.main.async {
            completion(takeScreenshot(of: rect, in: screen))
        }
    }
}
