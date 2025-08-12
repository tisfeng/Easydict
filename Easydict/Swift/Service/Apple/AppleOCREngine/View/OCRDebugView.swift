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
                sections: viewModel.sections,
                selectedSectionIndex: viewModel.selectedSectionIndex,
                onSectionTapped: { sectionIndex in
                    viewModel.selectedSectionIndex = sectionIndex
                }
            )
            .frame(minWidth: 400)

            // Right side: Text analysis results
            OCRTextResultsView(
                sections: viewModel.sections,
                sectionMergedTexts: viewModel.sectionMergedTexts,
                selectedSectionIndex: $viewModel.selectedSectionIndex
            )
            .frame(minWidth: 300)
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
        image: NSImage, sections: [[VNRecognizedTextObservation]], sectionMergedTexts: [String] = []
    ) {
        self.image = image
        self.sections = sections
        self.sectionMergedTexts = sectionMergedTexts

        // Default to first section if available
        if !sections.isEmpty {
            self.selectedSectionIndex = 0
        }
    }

    // MARK: Internal

    @Published var image: NSImage
    @Published var sections: [[VNRecognizedTextObservation]]
    @Published var sectionMergedTexts: [String]
    @Published var selectedSectionIndex: Int?

    /// Update the data without recreating the view
    func updateData(
        image: NSImage, sections: [[VNRecognizedTextObservation]], sectionMergedTexts: [String] = []
    ) {
        self.image = image
        self.sections = sections
        self.sectionMergedTexts = sectionMergedTexts

        // Reset to first section or stay within bounds
        if !sections.isEmpty {
            selectedSectionIndex = 0
        } else {
            selectedSectionIndex = -1
        }
    }
}

// MARK: - Preview

#Preview {
    let mockImage = NSImage(size: NSSize(width: 100, height: 100))
    let mockSections: [[VNRecognizedTextObservation]] = []
    let mockSectionMergedTexts: [String] = []
    let viewModel = OCRDebugViewModel(
        image: mockImage, sections: mockSections, sectionMergedTexts: mockSectionMergedTexts
    )

    return OCRDebugView(viewModel: viewModel)
        .frame(width: 1000, height: 700)
}
