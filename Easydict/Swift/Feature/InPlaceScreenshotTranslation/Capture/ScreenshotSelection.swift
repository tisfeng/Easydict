//
//  ScreenshotSelection.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import CoreGraphics

// MARK: - ScreenshotSelection

/// An immutable screenshot selection with enough geometry to start a live
/// ScreenCaptureKit session without rereading mutable global screenshot state.
struct ScreenshotSelection: @unchecked Sendable {
    // MARK: Lifecycle

    init(
        displayID: CGDirectDisplayID,
        screenFrameInGlobalPoints: CGRect,
        sourceRectInDisplayPoints: CGRect,
        backingScaleFactor: CGFloat,
        initialImage: NSImage
    ) {
        self.displayID = displayID
        self.screenFrameInGlobalPoints = screenFrameInGlobalPoints
        self.sourceRectInDisplayPoints = sourceRectInDisplayPoints
        self.backingScaleFactor = backingScaleFactor
        self.initialImage = Self.imageByLimitingLongEdge(initialImage)
    }

    // MARK: Internal

    let displayID: CGDirectDisplayID
    let screenFrameInGlobalPoints: CGRect
    let sourceRectInDisplayPoints: CGRect
    let backingScaleFactor: CGFloat
    let initialImage: NSImage

    /// The selection in AppKit global bottom-left coordinates.
    var globalFrameInScreenPoints: CGRect {
        CGRect(
            x: screenFrameInGlobalPoints.minX + sourceRectInDisplayPoints.minX,
            y: screenFrameInGlobalPoints.maxY - sourceRectInDisplayPoints.maxY,
            width: sourceRectInDisplayPoints.width,
            height: sourceRectInDisplayPoints.height
        )
    }

    // MARK: Private

    /// Matches the live ScreenCaptureKit pixel budget so a large Retina selection
    /// cannot make the first OCR generation disproportionately expensive.
    private static func imageByLimitingLongEdge(_ image: NSImage) -> NSImage {
        guard let cgImage = image.toCGImage() else { return image }
        let longEdge = max(cgImage.width, cgImage.height)
        guard longEdge > InPlaceTranslationConstants.maximumCaptureLongEdge else { return image }

        let scale = CGFloat(InPlaceTranslationConstants.maximumCaptureLongEdge) / CGFloat(longEdge)
        let width = max(1, Int((CGFloat(cgImage.width) * scale).rounded()))
        let height = max(1, Int((CGFloat(cgImage.height) * scale).rounded()))
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let scaledImage = context.makeImage() else { return image }
        return NSImage(cgImage: scaledImage, size: image.size)
    }
}
