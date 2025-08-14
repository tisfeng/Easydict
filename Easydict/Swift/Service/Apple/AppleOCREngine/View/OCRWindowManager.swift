//
//  OCRWindowManager.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import SwiftUI
import Vision

// MARK: - OCRWindowManager

/// Manager for creating and displaying OCR debug windows
@MainActor
class OCRWindowManager: ObservableObject {
    // MARK: Internal

    static let shared = OCRWindowManager()

    /// Shows the OCR debug window with the provided data
    /// - Parameters:
    ///   - image: The OCR source image
    ///   - ocrSections: Array of OCR sections containing observations, merged text, and language
    func showWindow(
        image: NSImage,
        ocrSections: [OCRSection]
    ) {
        if let existingWindow = ocrWindow {
            // Update existing window data
            if let viewModel = currentViewModel {
                viewModel.updateData(image: image, ocrSections: ocrSections)
            }
            existingWindow.orderFrontRegardless()
        } else {
            // Create new window with new ViewModel
            let viewModel = OCRDebugViewModel(image: image, sections: ocrSections)
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
            ocrWindow = window
            window.orderFrontRegardless()
        }
    }

    /// Closes the debug window if it's currently open
    func closeOCRWindow() {
        ocrWindow?.close()
        ocrWindow = nil
        currentViewModel = nil
    }

    // MARK: Private

    private var ocrWindow: NSWindow?
    private var currentViewModel: OCRDebugViewModel?
}
