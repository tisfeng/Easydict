//
//  OCRImageView.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/12.
//  Copyright © 2025 izual. All rights reserved.
//

import SwiftUI
import Vision

// MARK: - OCRImageView

/// SwiftUI view that displays the OCR image with bounding box overlays
struct OCRImageView: View {
    let image: NSImage
    let bands: [OCRBand]

    @Binding var selectedIndex: Int?

    var body: some View {
        VStack {
            Text(verbatim: "OCR Image with Bounding Boxes")
                .font(.headline)
                .padding(.top)

            ZStack {
                // Base image
                // Note: padding() will disturb observation bounding boxes
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .border(Color.gray.opacity(0.5))

                // Overlay with bounding boxes
                OCRBoundingBoxOverlay(
                    bands: bands,
                    selectedIndex: $selectedIndex,
                    imageSize: image.size
                )
            }
            .background(.gray.opacity(0.15)) // Image background may be white, so use a light gray
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding()
        }
    }
}

// MARK: - OCRBoundingBoxOverlay

/// Custom overlay view that draws bounding boxes on the image
struct OCRBoundingBoxOverlay: View {
    // MARK: Internal

    let bands: [OCRBand]
    @Binding var selectedIndex: Int?

    let imageSize: CGSize

    var body: some View {
        ZStack {
            // Canvas for drawing bounding boxes
            Canvas { context, size in
                // Calculate the actual image display area within the view
                let imageDisplayInfo = OCRImageGeometry.aspectFit(
                    viewSize: size,
                    imageSize: imageSize
                )

                // Get all sections from bands
                let allSections = bands.flatMap { $0.sections }

                // Draw bounding boxes order: observations, sections, bands
                // The border behind will cover the front one

                // Draw individual text observation bounding boxes (blue)
                for section in allSections {
                    for observation in section.observations {
                        drawTextObservationBoundingBox(
                            context: context,
                            observation: observation,
                            imageDisplayInfo: imageDisplayInfo
                        )
                    }
                }

                // Draw section bounding boxes
                for (sectionIndex, section) in allSections.enumerated() {
                    let sectionBoundingBox = section.observations.calculateSectionBoundingBox()
                    let isSelected = selectedIndex == sectionIndex

                    drawSectionBoundingBox(
                        context: context,
                        boundingBox: sectionBoundingBox,
                        imageDisplayInfo: imageDisplayInfo,
                        isSelected: isSelected
                    )
                }

                // Draw band bounding boxes
                for band in bands {
                    let observations = band.sections.flatMap { $0.observations }
                    let bandBoundingBox = observations.calculateSectionBoundingBox()
                    drawBandBoundingBox(
                        context: context,
                        boundingBox: bandBoundingBox,
                        imageDisplayInfo: imageDisplayInfo
                    )
                }
            }

            // Invisible overlay for handling taps
            GeometryReader { geometry in
                let imageDisplayInfo = OCRImageGeometry.aspectFit(
                    viewSize: geometry.size, imageSize: imageSize
                )

                // Get all sections from bands
                let allSections = bands.flatMap { $0.sections }

                // Add a single tap gesture to the entire area and determine which section was clicked
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        // Find which section was tapped based on coordinates
                        for (sectionIndex, section) in allSections.enumerated() {
                            let sectionBoundingBox = section.observations.calculateSectionBoundingBox()
                            let displayRect = OCRImageGeometry.displayRect(
                                forVisionNormalizedRect: sectionBoundingBox,
                                displayInfo: imageDisplayInfo
                            )

                            if displayRect.contains(location) {
                                withAnimation(.easeInOut(duration: .ocrDuration)) {
                                    selectedIndex = sectionIndex
                                }
                                return
                            }
                        }
                    }
            }
        }
    }

    // MARK: Private

    // MARK: - Drawing Functions

    /// Draw band bounding box with a thick green border
    private func drawBandBoundingBox(
        context: GraphicsContext,
        boundingBox: CGRect,
        imageDisplayInfo: OCRImageDisplayInfo
    ) {
        let rect = OCRImageGeometry.displayRect(
            forVisionNormalizedRect: boundingBox,
            displayInfo: imageDisplayInfo
        )
        let strokeWidth = 4.0

        // Draw thick red border for bands
        context.stroke(
            Path(rect),
            with: .color(.red),
            lineWidth: strokeWidth
        )
    }

    /// Draw section bounding box with different styles based on selection state
    private func drawSectionBoundingBox(
        context: GraphicsContext,
        boundingBox: CGRect,
        imageDisplayInfo: OCRImageDisplayInfo,
        isSelected: Bool
    ) {
        let rect = OCRImageGeometry.displayRect(
            forVisionNormalizedRect: boundingBox,
            displayInfo: imageDisplayInfo
        )
        let strokeWidth = 3.0

        if isSelected {
            // Selected: draw thick orange border with slight background highlight
            let selectedColor = Color.orange

            // Draw a slight background highlight
            context.fill(
                Path(rect),
                with: .color(selectedColor.opacity(0.15)) // orange is a good fill color
            )

            // Draw the border
            context.stroke(
                Path(rect),
                with: .color(selectedColor),
                lineWidth: strokeWidth
            )
        } else {
            // Unselected: draw thin green border
            context.stroke(
                Path(rect),
                with: .color(.green),
                lineWidth: strokeWidth
            )
        }
    }

    /// Draw individual text observation bounding box with a blue border
    private func drawTextObservationBoundingBox(
        context: GraphicsContext,
        observation: EZRecognizedTextObservation,
        imageDisplayInfo: OCRImageDisplayInfo
    ) {
        let rect = OCRImageGeometry.displayRect(
            forVisionNormalizedRect: observation.boundingBox,
            displayInfo: imageDisplayInfo
        )

        context.stroke(
            Path(rect),
            with: .color(.blue),
            lineWidth: 1.0
        )
    }
}
