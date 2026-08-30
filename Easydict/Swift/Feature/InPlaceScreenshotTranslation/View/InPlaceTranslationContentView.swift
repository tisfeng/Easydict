//
//  InPlaceTranslationContentView.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import SwiftUI

// MARK: - InPlaceTranslationContentView

/// Root panel content with an aspect-fit screenshot canvas and a non-scaling
/// responsive control surface below it.
struct InPlaceTranslationContentView: View {
    // MARK: Internal

    @ObservedObject var viewModel: InPlaceTranslationViewModel

    let placeholderImage: NSImage

    var body: some View {
        VStack(spacing: 0) {
            canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            InPlaceTranslationToolbar(viewModel: viewModel)
        }
        .frame(minWidth: 360, minHeight: 220)
        .background(.background)
    }

    // MARK: Private

    private var currentImage: Image {
        if let image = viewModel.snapshot?.image {
            return Image(decorative: image, scale: 1)
        }
        return Image(nsImage: placeholderImage)
    }

    private var currentImageSize: CGSize {
        if let image = viewModel.snapshot?.image {
            return CGSize(width: image.width, height: image.height)
        }
        return placeholderImage.size
    }

    private var canvas: some View {
        GeometryReader { geometry in
            let imageSize = currentImageSize
            let displayInfo = OCRImageGeometry.aspectFit(
                viewSize: geometry.size,
                imageSize: imageSize
            )

            ZStack {
                Color(nsColor: .underPageBackgroundColor)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedBlockID = nil
                    }
                currentImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                if viewModel.effectiveRenderMode == .translated,
                   let snapshot = viewModel.snapshot {
                    ForEach(snapshot.blocks) { block in
                        let displayRect = OCRImageGeometry.displayRect(
                            forTopLeftNormalizedRect: block.block.normalizedRect,
                            displayInfo: displayInfo,
                            padding: 3
                        )
                        InPlaceTranslationBlockView(
                            translatedBlock: block,
                            sourceImage: snapshot.image,
                            displayRect: displayRect,
                            rotation: blockRotation(
                                block.block.quadrilateral,
                                displayInfo: displayInfo
                            ),
                            isSelected: viewModel.selectedBlockID == block.id,
                            onSelect: { viewModel.selectedBlockID = block.id },
                            onCopy: {
                                viewModel.selectedBlockID = block.id
                                viewModel.copyTranslation()
                            }
                        )
                    }
                }
            }
            .clipped()
        }
    }

    private func blockRotation(
        _ quadrilateral: InPlaceOCRQuadrilateral?,
        displayInfo: OCRImageDisplayInfo
    )
        -> Angle {
        guard let quadrilateral else { return .zero }
        let deltaX = (quadrilateral.topRight.x - quadrilateral.topLeft.x)
            * displayInfo.size.width
        let deltaY = (quadrilateral.topRight.y - quadrilateral.topLeft.y)
            * displayInfo.size.height
        let radians = atan2(deltaY, deltaX)
        guard radians.isFinite, abs(radians) <= .pi / 6 else { return .zero }
        return .radians(radians)
    }
}
