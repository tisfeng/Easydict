//
//  NSImage+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/21.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

@objc
extension NSImage {
    /// Convert NSImage to CGImage.
    ///
    /// Attempts to directly obtain a CGImage. If that fails, falls back to TIFF conversion.
    /// - Returns: The CGImage representation of the NSImage, or nil if conversion fails.
    func toCGImage() -> CGImage? {
        return autoreleasepool {
            // First try direct conversion (works for most cases including NSCGImageSnapshotRep from PDF)
            var rect = CGRect(origin: .zero, size: size)
            if let cgImage = cgImage(forProposedRect: &rect, context: nil, hints: nil) {
                print("Direct CGImage conversion successful")
                return cgImage
            }

            print("Direct conversion failed, trying TIFF fallback")

            // Fallback to TIFF representation
            if let tiffData = tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData) {
                print("TIFF conversion successful")
                if let cgImage = bitmapImage.cgImage {
                    return cgImage
                }
            }

            print("TIFF conversion failed, no more fallback options available")
            return nil
        }
    }

    /// Crops the image to focus on a specific region with optional padding.
    /// - Parameters:
    ///   - rect: The region to crop, specified in Vision coordinates (0 to 1 range).
    ///   - padding: Padding to add around the text region (default: 0)
    /// - Returns: The cropped image, or nil if cropping fails
    func cropping(to rect: CGRect, padding: Double = 0) -> NSImage {
        let imageSize = size
        let imageWidth = imageSize.width
        let imageHeight = imageSize.height

        // Convert Vision coordinates to image coordinates
        // Vision: (0,0) at bottom-left, Y increases upward
        // NSImage: (0,0) at bottom-left, Y increases upward (same as Vision)

        // Calculate padded region in Vision coordinates
        let paddedMinX = max(0, rect.minX - padding)
        let paddedMaxX = min(1, rect.maxX + padding)
        let paddedMinY = max(0, rect.minY - padding)
        let paddedMaxY = min(1, rect.maxY + padding)

        // Convert to NSImage coordinates (points, not pixels)
        let cropMinX = paddedMinX * imageWidth
        let cropMaxX = paddedMaxX * imageWidth
        let cropMinY = paddedMinY * imageHeight
        let cropMaxY = paddedMaxY * imageHeight

        let cropWidth = cropMaxX - cropMinX
        let cropHeight = cropMaxY - cropMinY
        let cropOrigin = NSPoint(x: cropMinX, y: cropMinY)
        let cropSize = NSSize(width: cropWidth, height: cropHeight)

        let cropRect = NSRect(origin: cropOrigin, size: cropSize)
        let destRect = NSRect(origin: .zero, size: cropSize)

        print("Cropping image from \(imageSize) to region: \(cropRect)")

        // Create a new NSImage with the cropped size
        let croppedImage = NSImage(size: cropSize)
        croppedImage.lockFocus()
        draw(in: destRect, from: cropRect, operation: .copy, fraction: 1.0)
        croppedImage.unlockFocus()

        print("Cropped image size: \(croppedImage.size)")

        return croppedImage
    }
}
