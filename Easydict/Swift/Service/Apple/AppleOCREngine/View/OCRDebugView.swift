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
                bands: viewModel.bands,
                selectedIndex: $viewModel.selectedIndex
            )
            .frame(minWidth: 500)

            // Middle: Band analysis results
            OCRBandView(
                bands: viewModel.bands,
                selectedIndex: $viewModel.selectedIndex
            )
            .frame(minWidth: 300)

            // Right side: All Merged Text
            OCRMergedTextView(
                bands: viewModel.bands,
                mergedText: viewModel.mergedText
            )
            .frame(minWidth: 400)
        }
        .frame(
            minWidth: 1200,
            maxWidth: .infinity,
            minHeight: 600,
            maxHeight: .infinity
        )
    }
}

// MARK: - Preview

#Preview {
    let mockImage = NSImage(size: NSSize(width: 100, height: 100))
    let mockBands: [OCRBand] = []
    let viewModel = OCRDebugViewModel(
        image: mockImage, bands: mockBands, mergedText: "Sample merged text"
    )

    return OCRDebugView(viewModel: viewModel)
        .frame(width: 1200, height: 800)
}
