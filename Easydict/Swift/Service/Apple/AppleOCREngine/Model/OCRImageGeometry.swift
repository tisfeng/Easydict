//
//  OCRImageGeometry.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import CoreGraphics

// MARK: - OCRImageDisplayInfo

/// Describes the aspect-fit image rectangle inside a display surface.
struct OCRImageDisplayInfo: Equatable, Sendable {
    let size: CGSize
    let offset: CGPoint

    var rect: CGRect {
        CGRect(origin: offset, size: size)
    }
}

// MARK: - OCRImageGeometry

/// Centralizes Vision-to-SwiftUI coordinate conversion for OCR overlays.
/// All normalized output uses a top-left origin before it reaches product UI.
enum OCRImageGeometry {
    /// Calculates the aspect-fit image area, including any letterbox offset.
    static func aspectFit(viewSize: CGSize, imageSize: CGSize) -> OCRImageDisplayInfo {
        guard viewSize.width > 0,
              viewSize.height > 0,
              imageSize.width > 0,
              imageSize.height > 0
        else {
            return OCRImageDisplayInfo(size: .zero, offset: .zero)
        }

        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height
        let scale = min(widthScale, heightScale)
        let displaySize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        return OCRImageDisplayInfo(
            size: displaySize,
            offset: CGPoint(
                x: (viewSize.width - displaySize.width) / 2,
                y: (viewSize.height - displaySize.height) / 2
            )
        )
    }

    /// Converts a Vision normalized rectangle to a top-left normalized rectangle.
    static func topLeftNormalizedRect(fromVisionRect rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: 1 - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Converts a top-left normalized rectangle to Vision's bottom-left space.
    static func visionNormalizedRect(fromTopLeftRect rect: CGRect) -> CGRect {
        CGRect(
            x: rect.minX,
            y: 1 - rect.maxY,
            width: rect.width,
            height: rect.height
        )
    }

    /// Maps a Vision rectangle into an aspect-fit display surface.
    static func displayRect(
        forVisionNormalizedRect rect: CGRect,
        displayInfo: OCRImageDisplayInfo,
        padding: CGFloat = 0
    )
        -> CGRect {
        let topLeftRect = topLeftNormalizedRect(fromVisionRect: rect)
        let mapped = CGRect(
            x: displayInfo.offset.x + topLeftRect.minX * displayInfo.size.width,
            y: displayInfo.offset.y + topLeftRect.minY * displayInfo.size.height,
            width: topLeftRect.width * displayInfo.size.width,
            height: topLeftRect.height * displayInfo.size.height
        )
        guard padding > 0 else { return mapped }
        return mapped.insetBy(dx: -padding, dy: -padding)
            .intersection(displayInfo.rect)
    }

    /// Maps a top-left normalized rectangle into an aspect-fit display surface.
    static func displayRect(
        forTopLeftNormalizedRect rect: CGRect,
        displayInfo: OCRImageDisplayInfo,
        padding: CGFloat = 0
    )
        -> CGRect {
        displayRect(
            forVisionNormalizedRect: visionNormalizedRect(fromTopLeftRect: rect),
            displayInfo: displayInfo,
            padding: padding
        )
    }
}
