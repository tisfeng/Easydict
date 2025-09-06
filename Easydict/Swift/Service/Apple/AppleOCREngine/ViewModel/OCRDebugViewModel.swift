//
//  OCRDebugViewModel.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/18.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - OCRDebugViewModel

/// ViewModel for OCR debug data
@MainActor
class OCRDebugViewModel: ObservableObject {
    // MARK: Lifecycle

    init(image: NSImage, bands: [OCRBand], mergedText: String, isPinned: Bool = false) {
        self.image = image
        self.bands = bands
        self.mergedText = mergedText
        self.isPinned = isPinned
        self.selectedIndex = bands.isEmpty ? nil : 0
    }

    // MARK: Internal

    @Published var image: NSImage
    @Published var bands: [OCRBand]
    @Published var selectedIndex: Int?
    @Published var mergedText: String

    /// Callback for pin state changes - allows external components to respond
    var onPinStateChanged: ((Bool) -> ())?

    @Published var isPinned: Bool = false {
        didSet {
            // Only notify if the value actually changed
            if oldValue != isPinned {
                onPinStateChanged?(isPinned)
            }
        }
    }

    /// Update the data without recreating the view
    func updateData(image: NSImage, bands: [OCRBand], mergedText: String) {
        self.image = image
        self.bands = bands
        self.mergedText = mergedText

        // Reset to first section or stay within bounds
        let totalSections = bands.flatMap { $0.sections }.count
        if totalSections > 0 {
            selectedIndex = 0
        } else {
            selectedIndex = nil
        }
        // Note: isPinned state is preserved during data updates
    }

    /// Toggle the pin state
    func togglePinState() {
        isPinned.toggle()
    }
}
