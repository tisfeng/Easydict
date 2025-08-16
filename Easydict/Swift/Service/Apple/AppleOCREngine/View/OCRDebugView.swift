//
//  OCRDebugView.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import SwiftUI
import Vision

// MARK: - OCRDebugView

/// Main view for OCR debugging interface
struct OCRDebugView: View {
    // MARK: Lifecycle

    init(viewModel: OCRDebugViewModel) {
        self.viewModel = viewModel
    }

    // MARK: Internal

    @ObservedObject var viewModel: OCRDebugViewModel

    var body: some View {
        HSplitView {
            // Left side: Image with overlay
            OCRImageView(
                image: viewModel.image,
                sections: viewModel.ocrSections.map { $0.observations },
                selectedIndex: $viewModel.selectedIndex
            )
            .frame(minWidth: 400)

            // Middle: Text analysis results
            OCRSectionView(
                ocrSections: viewModel.ocrSections,
                selectedIndex: $viewModel.selectedIndex
            )
            .frame(minWidth: 300)

            // Right side: All Merged Text
            OCRMergedTextView(
                ocrSections: viewModel.ocrSections,
                mergedText: viewModel.mergedText
            )
            .frame(minWidth: 400)
        }
        .frame(
            minWidth: 1100,
            maxWidth: .infinity,
            minHeight: 600,
            maxHeight: .infinity
        )
    }
}

// MARK: - OCRDebugViewModel

/// ViewModel for OCR debug data
@MainActor
class OCRDebugViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        image: NSImage,
        ocrSections: [OCRSection],
        mergedText: String
    ) {
        self.image = image
        self.ocrSections = ocrSections
        self.mergedText = mergedText

        // Default to first section if available
        if !ocrSections.isEmpty {
            self.selectedIndex = 0
        }
    }

    // MARK: Internal

    @Published var image: NSImage
    @Published var ocrSections: [OCRSection]
    @Published var selectedIndex: Int?
    @Published var mergedText: String

    /// Update the data without recreating the view
    func updateData(image: NSImage, ocrSections: [OCRSection], mergedText: String) {
        self.image = image
        self.ocrSections = ocrSections
        self.mergedText = mergedText

        // Reset to first section or stay within bounds
        if !ocrSections.isEmpty {
            selectedIndex = 0
        } else {
            selectedIndex = -1
        }
    }
}

// MARK: - Preview

#Preview {
    let mockImage = NSImage(size: NSSize(width: 100, height: 100))
    let mockSectionMetrics: [OCRSection] = []
    let viewModel = OCRDebugViewModel(
        image: mockImage, ocrSections: mockSectionMetrics, mergedText: "Sample merged text"
    )

    return OCRDebugView(viewModel: viewModel)
        .frame(width: 1200, height: 800)
}
