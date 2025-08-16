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
    let sections: [[VNRecognizedTextObservation]]
    @Binding var selectedIndex: Int?

    var body: some View {
        VStack {
            Text(verbatim: "OCR Image with Bounding Boxes")
                .font(.headline)
                .padding(.top)

            GeometryReader { geometry in
                ZStack {
                    // Base image
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)

                    // Overlay with bounding boxes
                    OCRBoundingBoxOverlay(
                        sections: sections,
                        selectedIndex: $selectedIndex,
                        imageSize: image.size,
                        viewSize: geometry.size
                    )
                }
            }
            .border(Color.gray.opacity(0.5), width: 1)
            .padding()
        }
    }
}

// MARK: - OCRBoundingBoxOverlay

/// Custom overlay view that draws bounding boxes on the image
struct OCRBoundingBoxOverlay: View {
    // MARK: Internal

    let sections: [[VNRecognizedTextObservation]]
    @Binding var selectedIndex: Int?
    let imageSize: CGSize
    let viewSize: CGSize

    var body: some View {
        ZStack {
            // Canvas for drawing bounding boxes
            Canvas { context, size in
                // Calculate the actual image display area within the view
                let imageDisplayInfo = calculateImageDisplayInfo(
                    viewSize: size, imageSize: imageSize
                )

                // Draw section bounding boxes (red for unselected, orange for selected)
                for (sectionIndex, section) in sections.enumerated() {
                    let sectionBoundingBox = section.calculateSectionBoundingBox()
                    let isSelected = selectedIndex == sectionIndex

                    drawSectionBoundingBox(
                        context: context,
                        boundingBox: sectionBoundingBox,
                        imageDisplayInfo: imageDisplayInfo,
                        isSelected: isSelected
                    )
                }

                // Draw individual text observation bounding boxes (blue)
                for section in sections {
                    for observation in section {
                        drawTextObservationBoundingBox(
                            context: context,
                            observation: observation,
                            imageDisplayInfo: imageDisplayInfo
                        )
                    }
                }
            }

            // Invisible overlay for handling taps
            GeometryReader { geometry in
                let imageDisplayInfo = calculateImageDisplayInfo(
                    viewSize: geometry.size, imageSize: imageSize
                )

                // Add a single tap gesture to the entire area and determine which section was clicked
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        // Find which section was tapped based on coordinates
                        for (sectionIndex, section) in sections.enumerated() {
                            let sectionBoundingBox = section.calculateSectionBoundingBox()
                            let displayRect = convertVisionRectToDisplayRect(
                                sectionBoundingBox, imageDisplayInfo: imageDisplayInfo
                            )

                            if displayRect.contains(location) {
                                print("Tapped section \(sectionIndex) at \(location)") // Debug print
                                selectedIndex = sectionIndex
                                return
                            }
                        }
                        print("Tapped outside sections at \(location)") // Debug print
                    }
            }
        }
    }

    // MARK: Private

    private func calculateImageDisplayInfo(viewSize: CGSize, imageSize: CGSize) -> ImageDisplayInfo {
        let imageAspectRatio = imageSize.width / imageSize.height
        let viewAspectRatio = viewSize.width / viewSize.height

        let displaySize: CGSize
        let displayOffset: CGPoint

        if imageAspectRatio > viewAspectRatio {
            // Image is wider than view - fit to width
            displaySize = CGSize(
                width: viewSize.width,
                height: viewSize.width / imageAspectRatio
            )
        } else {
            // Image is taller than view - fit to height
            displaySize = CGSize(
                width: viewSize.height * imageAspectRatio,
                height: viewSize.height
            )
        }

        displayOffset = CGPoint(
            x: (viewSize.width - displaySize.width) / 2,
            y: (viewSize.height - displaySize.height) / 2
        )

        return ImageDisplayInfo(size: displaySize, offset: displayOffset)
    }

    private func drawSectionBoundingBox(
        context: GraphicsContext,
        boundingBox: CGRect,
        imageDisplayInfo: ImageDisplayInfo,
        isSelected: Bool
    ) {
        let rect = convertVisionRectToDisplayRect(boundingBox, imageDisplayInfo: imageDisplayInfo)
        let strokeWidth = 3.0

        if isSelected {
            // Selected: draw thick orange border with slight background highlight
            let orangeColor = Color.orange

            // Draw a slight background highlight
            context.fill(
                Path(rect),
                with: .color(orangeColor.opacity(0.1))
            )

            // Draw the border
            context.stroke(
                Path(rect),
                with: .color(orangeColor),
                lineWidth: strokeWidth
            )
        } else {
            // Unselected: draw thin red border
            context.stroke(
                Path(rect),
                with: .color(.red),
                lineWidth: strokeWidth
            )
        }
    }

    private func drawTextObservationBoundingBox(
        context: GraphicsContext,
        observation: VNRecognizedTextObservation,
        imageDisplayInfo: ImageDisplayInfo
    ) {
        let rect = convertVisionRectToDisplayRect(
            observation.boundingBox, imageDisplayInfo: imageDisplayInfo
        )

        context.stroke(
            Path(rect),
            with: .color(.blue),
            lineWidth: 1.0
        )
    }

    private func convertVisionRectToDisplayRect(
        _ visionRect: CGRect, imageDisplayInfo: ImageDisplayInfo
    )
        -> CGRect {
        // Vision coordinates: (0,0) at bottom-left, Y increases upward
        // SwiftUI coordinates: (0,0) at top-left, Y increases downward

        let displayX = imageDisplayInfo.offset.x + (visionRect.minX * imageDisplayInfo.size.width)
        let displayY =
            imageDisplayInfo.offset.y + ((1.0 - visionRect.maxY) * imageDisplayInfo.size.height)
        let displayWidth = visionRect.width * imageDisplayInfo.size.width
        let displayHeight = visionRect.height * imageDisplayInfo.size.height

        return CGRect(
            x: displayX,
            y: displayY,
            width: displayWidth,
            height: displayHeight
        )
    }
}

// MARK: - ImageDisplayInfo

struct ImageDisplayInfo {
    let size: CGSize
    let offset: CGPoint
}
