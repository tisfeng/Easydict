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
    ///   - bands: Array of OCR bands containing sections with observations, merged text, and language
    ///   - mergedText: The final merged text from all bands
    func showWindow(
        image: NSImage,
        bands: [OCRBand],
        mergedText: String
    ) {
        if ocrWindow == nil {
            // Create new window with new ViewModel
            let viewModel = OCRDebugViewModel(
                image: image,
                bands: bands,
                mergedText: mergedText
            )
            currentViewModel = viewModel

            let debugView = OCRDebugView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: debugView)

            let screen = NSScreen.main ?? NSScreen.screens.first!
            let screenVisibleFrame = screen.visibleFrame

            // Create the window to fill the visible screen area
            let window = NSWindow(
                contentRect: screenVisibleFrame,
                styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            window.title = "OCR Debug Preview"
            window.contentViewController = hostingController

            // Ensure the window fills the visible frame
            window.setFrame(screenVisibleFrame, display: true)
            window.isReleasedWhenClosed = false

            // Store reference and show
            ocrWindow = window
            window.makeKeyAndOrderFront(nil)
        } else {
            // Update existing window data
            if let viewModel = currentViewModel {
                viewModel.updateData(
                    image: image,
                    bands: bands,
                    mergedText: mergedText
                )
            }
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
