//
//  OCRImageGeometryTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics
import Testing

@testable import Easydict

/// Exercises the shared Vision, normalized, and aspect-fit coordinate contract.
@Suite("OCR Image Geometry", .tags(.inPlaceTranslation, .ocr, .unit))
struct OCRImageGeometryTests {
    // MARK: Internal

    @Test("Aspect fit centers a wide image with vertical letterboxing")
    func calculatesWideImageAspectFit() {
        let display = OCRImageGeometry.aspectFit(
            viewSize: CGSize(width: 400, height: 400),
            imageSize: CGSize(width: 800, height: 400)
        )

        #expect(display.size == CGSize(width: 400, height: 200))
        #expect(display.offset == CGPoint(x: 0, y: 100))
    }

    @Test("Invalid image or view sizes produce an empty display area")
    func rejectsInvalidAspectFitInputs() {
        #expect(
            OCRImageGeometry.aspectFit(
                viewSize: CGSize(width: 0, height: 100),
                imageSize: CGSize(width: 100, height: 100)
            ) == OCRImageDisplayInfo(size: .zero, offset: .zero)
        )
        #expect(
            OCRImageGeometry.aspectFit(
                viewSize: CGSize(width: 100, height: 100),
                imageSize: CGSize(width: -1, height: 100)
            ) == OCRImageDisplayInfo(size: .zero, offset: .zero)
        )
    }

    @Test("Vision and top-left normalized rectangles round trip")
    func convertsNormalizedCoordinateOrigins() {
        let visionRect = CGRect(x: 0.125, y: 0.2, width: 0.5, height: 0.3)

        let topLeft = OCRImageGeometry.topLeftNormalizedRect(fromVisionRect: visionRect)

        #expect(
            rectsAreApproximatelyEqual(
                topLeft,
                CGRect(x: 0.125, y: 0.5, width: 0.5, height: 0.3)
            )
        )
        #expect(
            rectsAreApproximatelyEqual(
                OCRImageGeometry.visionNormalizedRect(fromTopLeftRect: topLeft),
                visionRect
            )
        )
    }

    @Test("Maps and pads a Vision rectangle inside the aspect-fit image")
    func mapsVisionRectIntoDisplaySurface() {
        let display = OCRImageDisplayInfo(
            size: CGSize(width: 400, height: 200),
            offset: CGPoint(x: 0, y: 100)
        )

        let mapped = OCRImageGeometry.displayRect(
            forVisionNormalizedRect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
            displayInfo: display,
            padding: 10
        )

        #expect(rectsAreApproximatelyEqual(mapped, CGRect(x: 90, y: 140, width: 220, height: 120)))
    }

    @Test("Padding is clipped to the image instead of entering letterbox space")
    func clipsPaddedRectToImageBounds() {
        let display = OCRImageDisplayInfo(
            size: CGSize(width: 400, height: 200),
            offset: CGPoint(x: 0, y: 100)
        )

        let mapped = OCRImageGeometry.displayRect(
            forVisionNormalizedRect: CGRect(x: 0, y: 0.8, width: 0.1, height: 0.2),
            displayInfo: display,
            padding: 10
        )

        #expect(rectsAreApproximatelyEqual(mapped, CGRect(x: 0, y: 100, width: 50, height: 50)))
    }

    // MARK: Private

    private func rectsAreApproximatelyEqual(
        _ lhs: CGRect,
        _ rhs: CGRect,
        tolerance: CGFloat = 0.000_001
    )
        -> Bool {
        abs(lhs.minX - rhs.minX) <= tolerance
            && abs(lhs.minY - rhs.minY) <= tolerance
            && abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }
}
