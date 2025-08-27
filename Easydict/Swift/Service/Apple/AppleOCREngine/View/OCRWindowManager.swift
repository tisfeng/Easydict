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
class OCRWindowManager {
    // MARK: Internal

    static let shared = OCRWindowManager()

    /// Shows the OCR debug window with the provided data
    /// - Parameters:
    ///   - image: The OCR source image (can be nil for empty window)
    ///   - bands: Array of OCR bands containing sections with observations, merged text, and language
    ///   - mergedText: The final merged text from all bands
    func showWindow(
        image: NSImage? = nil,
        bands: [OCRBand] = [],
        mergedText: String = ""
    ) {
        logInfo("Showing OCR Debug Window")

        if ocrWindow == nil {
            logInfo("Creating new OCR Debug Window")
            createWindow(image: image, bands: bands, mergedText: mergedText)
        } else {
            logInfo("Updating existing OCR Debug Window")
            updateWindow(image: image, bands: bands, mergedText: mergedText)
        }

        displayWindow()
    }

    // MARK: Private

    private var ocrWindow: OCRWindow?
    private var currentViewModel: OCRDebugViewModel?

    /// Create a new OCR window with the provided data
    private func createWindow(image: NSImage?, bands: [OCRBand], mergedText: String) {
        let windowImage = image ?? NSImage(systemSymbol: .docTextImage)

        let viewModel = OCRDebugViewModel(
            image: windowImage,
            bands: bands,
            mergedText: mergedText,
            isPinned: false
        )

        // Set up callback for pin state changes
        viewModel.onPinStateChanged = { [weak self] isPinned in
            self?.updateWindowPin(isPinned: isPinned)
        }

        currentViewModel = viewModel

        let debugView = OCRDebugView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: debugView)

        let screenVisibleFrame = EZWindowManager.shared().screenVisibleFrame

        // Create the custom OCR window
        let window = OCRWindow(
            contentRect: screenVisibleFrame,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = hostingController

        // Calculate and set window frame
        let windowFrame = calculateWindowFrame(for: screenVisibleFrame)
        window.setFrame(windowFrame, display: true)

        // Store reference
        ocrWindow = window
    }

    /// Update existing window with new data
    private func updateWindow(image: NSImage?, bands: [OCRBand], mergedText: String) {
        guard let image, let viewModel = currentViewModel else { return }

        viewModel.updateData(
            image: image,
            bands: bands,
            mergedText: mergedText
        )
    }

    /// Display the OCR window and ensure it gets focus
    private func displayWindow() {
        guard let window = ocrWindow else { return }

        logInfo("Making OCR window key and ordering front")

        NSApplication.shared.activateApp()
        window.makeKeyAndOrderFront(nil)
        window.level = .normal

        logInfo("OCR window isKey: \(window.isKeyWindow)")
        logInfo("OCR window isVisible: \(window.isVisible)")
    }

    /// Calculate the frame for the OCR window based on screen dimensions
    private func calculateWindowFrame(for screenFrame: NSRect) -> NSRect {
        let sizeRatio: CGFloat = 0.75

        let windowSize = NSSize(
            width: screenFrame.width * sizeRatio,
            height: screenFrame.height * sizeRatio
        )

        // Position window at top-left of screen
        let windowOrigin = NSPoint(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - windowSize.height
        )

        return NSRect(origin: windowOrigin, size: windowSize)
    }

    /// Updates the window pin state to the specified value
    private func updateWindowPin(isPinned: Bool) {
        guard let window = ocrWindow else { return }
        window.isPinned = isPinned
    }
}

// MARK: - NSApplication Extension

extension NSApplication {
    /// Convenience method to activate the application
    func activateApp() {
        if #available(macOS 14.0, *) {
            self.activate()
        } else {
            activate(ignoringOtherApps: true)
        }
    }
}
