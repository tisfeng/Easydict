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

    init(
        image: NSImage,
        bands: [OCRBand],
        mergedText: String
    ) {
        self.image = image
        self.bands = bands
        self.mergedText = mergedText

        // Default to first section if available
        let totalSections = bands.flatMap { $0.sections }.count
        if totalSections > 0 {
            self.selectedIndex = 0
        }
    }

    // MARK: Internal

    @Published var image: NSImage
    @Published var bands: [OCRBand]
    @Published var selectedIndex: Int?
    @Published var mergedText: String

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
    }
}
