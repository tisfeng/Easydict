//
//  OCRDebugWindowManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import SwiftUI
import Vision

// MARK: - OCRDebugWindowManager

/// Manager for creating and displaying OCR debug windows
@MainActor
class OCRDebugWindowManager: ObservableObject {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = OCRDebugWindowManager()

    /// Returns true if the debug window is currently open
    var isDebugWindowOpen: Bool {
        debugWindow != nil && debugWindow?.isVisible == true
    }

    /// Shows the OCR debug window with the provided data
    /// - Parameters:
    ///   - image: The OCR source image
    ///   - sections: Array of sections containing VNRecognizedTextObservation arrays
    func showDebugWindow(
        image: NSImage,
        sections: [[VNRecognizedTextObservation]]
    ) {
        if let existingWindow = debugWindow, existingWindow.isVisible {
            // Update existing window data
            if let viewModel = currentViewModel {
                viewModel.updateData(image: image, sections: sections)
            }
            existingWindow.orderFrontRegardless()
        } else {
            // Create new window with new ViewModel
            let viewModel = OCRDebugViewModel(image: image, sections: sections)
            currentViewModel = viewModel

            let debugView = OCRDebugView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: debugView)

            // Calculate window size based on screen height
            let screen = NSScreen.main ?? NSScreen.screens.first!
            let screenVisibleFrame = screen.visibleFrame
            let windowSize = screenVisibleFrame.height

            // Create the window
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: windowSize, height: windowSize),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered,
                defer: false
            )

            window.title = "OCR Debug Preview"
            window.contentViewController = hostingController

            // Force set the window frame to our desired size and position
            let desiredFrame = NSRect(
                x: screenVisibleFrame.origin.x,
                y: 0,
                width: windowSize * 1.2,
                height: windowSize
            )
            window.setFrame(desiredFrame, display: true)

            window.isReleasedWhenClosed = false

            // Store reference and show
            debugWindow = window
            window.orderFrontRegardless()
        }
    }

    /// Closes the debug window if it's currently open
    func closeDebugWindow() {
        debugWindow?.close()
        debugWindow = nil
        currentViewModel = nil
    }

    // MARK: Private

    private var debugWindow: NSWindow?
    private var currentViewModel: OCRDebugViewModel?
}

// MARK: - Global Function for Easy Access

/// Global function to easily show OCR debug window from anywhere in the app
/// - Parameters:
///   - image: The OCR source image
///   - sections: Array of sections containing VNRecognizedTextObservation arrays
@MainActor
func showOCRDebugWindow(
    image: NSImage,
    sections: [[VNRecognizedTextObservation]]
) {
    OCRDebugWindowManager.shared.showDebugWindow(image: image, sections: sections)
}
