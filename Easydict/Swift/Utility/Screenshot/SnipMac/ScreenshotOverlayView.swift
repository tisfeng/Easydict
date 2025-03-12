//
//  ScreenshotOverlayView.swift
//  Easydict
//
//  Created by tisfeng on 2025/3/11.
//  Copyright © 2025 izual. All rights reserved.
//

import Carbon
import SwiftUI

struct ScreenshotOverlayView: View {
    // MARK: Lifecycle

    init() {
        // Get screen screenshot as background during initialization
        _backgroundImage = State(initialValue: ScreenCaptureManager.takeScreenshot(of: nil))
    }

    // MARK: Internal

    let overlayWindowManager = OverlayWindowManager.shared

    var drag: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let adjustedStartLocation = CGPoint(
                    x: value.startLocation.x,
                    y: value.startLocation.y
                )
                let adjustedLocation = CGPoint(
                    x: value.location.x,
                    y: value.location.y
                )

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
            }
            .onEnded { _ in
                isSelecting = false
                overlayWindowManager.hideOverlayWindow()

                print("Selected rect: \(selectedRect)")

                // Crop the selected area from the background image
                if selectedRect.width > 10, selectedRect.height > 10 {
                    // Directly use ScreenCaptureManager to get screenshot of the selected area
                    if let croppedImage = ScreenCaptureManager.takeScreenshot(of: selectedRect) {
                        OverlayWindowManager.shared.finishCapture(with: croppedImage)
                    }
                }
            }
    }

    var body: some View {
        ZStack {
            // Display background screenshot
            if let image = backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.2)
            }

            GeometryReader { geometry in
                ZStack {
                    // Dark mask when selecting, turn to transparent when mouse moving.
                    Rectangle()
                        .fill(Color.black.opacity(isMouseMoved ? 0 : 0.3))
                        .edgesIgnoringSafeArea(.all)
//                        .animation(.easeOut(duration: 0.2), value: isMouseMoved)
                        .onAppear {
                            NSLog("onAppear mask, isMouseMoved: \(isMouseMoved)")
                        }

                    if isSelecting {
                        // Selection area
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                            .background(Color.clear)
                            .frame(width: selectedRect.width, height: selectedRect.height)
                            .position(
                                x: selectedRect.midX,
                                y: selectedRect.midY
                            )

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
                .compositingGroup()

                // Gesture recognition layer
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(drag)
            }
        }
        .onAppear {
            NSLog("onAppear")
            setupKeyboardMonitor()
            setupMouseMonitor()
            isMouseMoved = false
        }
        .onDisappear {
            NSLog("Remove monitors")
            removeKeyboardMonitor()
            removeMouseMonitor()
        }
    }

    // MARK: Private

    @State private var selectedRect = CGRect.zero
    @State private var isSelecting = false
    @State private var backgroundImage: NSImage?
    @State private var isMouseMoved = false
    @State private var mouseMonitor: Any?

    // Modified to array to store multiple monitors
    @State private var keyboardMonitors: [Any] = []
    @State private var keyboardMonitor: Any?

    private func setupMouseMonitor() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            if !isMouseMoved {
                DispatchQueue.main.async {
                    isMouseMoved = true
                    NSLog("Mouse moved, isMouseMoved: \(isMouseMoved)")
                }
            }
        }
    }

    private func removeMouseMonitor() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
    }

    private func setupKeyboardMonitor() {
        // Ensure no duplicate monitors
        removeKeyboardMonitor()

        NSLog("Set up keyboard monitor")
        // Use global monitor instead of local monitor
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            NSLog("Global key: \(event.keyCode)")

            if event.keyCode == kVK_Escape { // ESC key
                NSLog("ESC key detected, close window")
                DispatchQueue.main.async {
                    OverlayWindowManager.shared.hideOverlayWindow()
                }
            }
        }

        // Also add local monitor as backup
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            NSLog("Local key: \(event.keyCode)")

            if event.keyCode == kVK_Escape { // ESC key
                NSLog("ESC key detected, close window")
                DispatchQueue.main.async {
                    OverlayWindowManager.shared.hideOverlayWindow()
                }
                return nil
            }
            return event
        }

        // Save both monitors
        keyboardMonitors = [keyboardMonitor, localMonitor].compactMap { $0 }
    }

    // Method to remove monitors
    private func removeKeyboardMonitor() {
        for monitor in keyboardMonitors {
            NSEvent.removeMonitor(monitor)
        }
        keyboardMonitors = []
        NSLog("Remove all keyboard monitors")
    }
}
