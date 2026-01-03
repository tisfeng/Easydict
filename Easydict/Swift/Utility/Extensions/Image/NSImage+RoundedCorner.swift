//
//  NSImage+RoundedCorner.swift
//  Airy
//
//  Created by isfeng on 2025/11/14.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSImage {
    /// Clip the image with rounded corners
    ///
    /// - Parameter cornerRadius: Corner radius
    /// - Returns: Clipped image with rounded corners
    func clip(cornerRadius: CGFloat) -> NSImage {
        let imageSize = size

        // Get the actual pixel size from the image representation to handle Retina displays
        guard let representation = representations.first else {
            return self
        }

        let pixelWidth = representation.pixelsWide
        let pixelHeight = representation.pixelsHigh
        let scale = CGFloat(pixelWidth) / imageSize.width

        // Create a bitmap context with the correct scale for sharp rendering
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return self
        }

        // Enable high-quality rendering
        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        context.setAllowsAntialiasing(true)

        // Scale the context to handle Retina displays
        context.scaleBy(x: scale, y: scale)

        // Create rounded rect path
        let rect = CGRect(origin: .zero, size: imageSize)
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        // Clip to the rounded rect
        context.addPath(path)
        context.clip()

        // Draw the image
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext

        draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)

        NSGraphicsContext.restoreGraphicsState()

        // Create the final image from the context
        guard let cgImage = context.makeImage() else {
            return self
        }

        let newImage = NSImage(cgImage: cgImage, size: imageSize)
        return newImage
    }
}
