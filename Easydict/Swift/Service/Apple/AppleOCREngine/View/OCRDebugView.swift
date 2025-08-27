//
//  OCRDebugView.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
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
        VStack(spacing: 0) {
            // Custom title bar with controls
            customTitleBar

            // Main content
            HSplitView {
                // Left side: Image with overlay
                OCRImageView(
                    image: viewModel.image,
                    bands: viewModel.bands,
                    selectedIndex: $viewModel.selectedIndex
                )
                .frame(minWidth: 420)

                // Middle: Band analysis results
                OCRBandView(
                    bands: viewModel.bands,
                    selectedIndex: $viewModel.selectedIndex
                )
                .frame(minWidth: 260)

                // Right side: All Merged Text
                OCRMergedTextView(
                    bands: viewModel.bands,
                    mergedText: viewModel.mergedText
                )
                .frame(minWidth: 320)
            }
        }
        .frame(
            minWidth: 1000,
            maxWidth: .infinity,
            minHeight: 600,
            maxHeight: .infinity
        )
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    // MARK: Private

    @ViewBuilder
    private var customTitleBar: some View {
        HStack {
            let width = 25.0

            // Window pin toggle button
            Button(action: {
                viewModel.togglePinState()
            }) {
                let pinImageName = viewModel.isPinned ? "new_pin_selected" : "new_pin_normal"
                Image(nsImage: NSImage(named: pinImageName)!)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(viewModel.isPinned ? .blue : .gray)
                    .frame(width: width, height: width)
            }
            .buttonStyle(.borderless)

            Spacer()

            // Title (centered)
            Text(verbatim: "OCR Debug Preview")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            // Invisible spacer to balance the left button for perfect centering
            Color.clear.frame(width: width, height: width)
        }
        .frame(height: 45)
        .padding(.horizontal, 10)
        .background(
            VisualEffectView(material: .titlebar, blendingMode: .behindWindow)
        )
        .overlay(
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - VisualEffectView

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
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
