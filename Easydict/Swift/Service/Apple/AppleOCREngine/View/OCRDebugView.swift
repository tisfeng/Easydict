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
                selectedIndex: $viewModel.selectedSectionIndex
            )
            .frame(minWidth: 450)

            // Right side: Text analysis results
            OCRTextResultsView(
                ocrSections: viewModel.ocrSections,
                selectedIndex: $viewModel.selectedSectionIndex
            )
            .frame(minWidth: 350)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - OCRDebugViewModel

/// ViewModel for OCR debug data
@MainActor
class OCRDebugViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        image: NSImage,
        sections: [OCRSection]
    ) {
        self.image = image
        self.ocrSections = sections

        // Default to first section if available
        if !sections.isEmpty {
            self.selectedSectionIndex = 0
        }
    }

    // MARK: Internal

    @Published var image: NSImage
    @Published var ocrSections: [OCRSection]
    @Published var selectedSectionIndex: Int?

    /// Update the data without recreating the view
    func updateData(image: NSImage, ocrSections: [OCRSection]) {
        self.image = image
        self.ocrSections = ocrSections

        // Reset to first section or stay within bounds
        if !ocrSections.isEmpty {
            selectedSectionIndex = 0
        } else {
            selectedSectionIndex = -1
        }
    }
}

// MARK: - Preview

#Preview {
    let mockImage = NSImage(size: NSSize(width: 100, height: 100))
    let mockSections: [OCRSection] = []
    let viewModel = OCRDebugViewModel(image: mockImage, sections: mockSections)

    return OCRDebugView(viewModel: viewModel)
        .frame(width: 1000, height: 700)
}
