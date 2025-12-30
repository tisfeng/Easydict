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
        // First try direct conversion (works for most cases including NSCGImageSnapshotRep from PDF)
        var rect = CGRect(origin: .zero, size: size)
        if let cgImage = cgImage(forProposedRect: &rect, context: nil, hints: nil) {
            logInfo("Direct CGImage conversion successful")
            return cgImage
        }

        logInfo("Direct conversion failed, trying TIFF fallback")

        // Fallback to TIFF representation
        if let tiffData = tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData) {
            logInfo("TIFF conversion successful")
            if let cgImage = bitmapImage.cgImage {
                return cgImage
            }
        }

        logInfo("TIFF conversion failed, no more fallback options available")
        return nil
    }

    /// Crops the image to focus on a specific region with optional padding.
    /// Uses Core Graphics to properly handle Retina displays and avoid deprecated methods.
    ///
    /// - Parameters:
    ///   - rect: The region to crop, specified in Vision coordinates (0 to 1 range).
    ///   - padding: Padding to add around the text region (default: 0)
    /// - Returns: The cropped image, or nil if cropping fails
    func cropping(to rect: CGRect, padding: Double = 0) -> NSImage? {
        // Get the best representation for this image
        guard let rep = bestRepresentation(for: .zero, context: nil, hints: nil) else {
            logInfo("No valid representation found for image")
            return nil
        }

        // Get pixel dimensions from the representation
        let pixelWidth = rep.pixelsWide
        let pixelHeight = rep.pixelsHigh

        // Convert Vision coordinates to pixel coordinates
        // Vision: (0,0) at bottom-left, Y increases upward
        // NSImage: (0,0) at bottom-left, Y increases upward (same as Vision)

        // Calculate padded region in Vision coordinates
        let paddedMinX = max(0, rect.minX - padding)
        let paddedMaxX = min(1, rect.maxX + padding)
        let paddedMinY = max(0, rect.minY - padding)
        let paddedMaxY = min(1, rect.maxY + padding)

        // Convert to pixel coordinates
        let cropMinX = Int(paddedMinX * Double(pixelWidth))
        let cropMaxX = Int(paddedMaxX * Double(pixelWidth))
        let cropMinY = Int(paddedMinY * Double(pixelHeight))
        let cropMaxY = Int(paddedMaxY * Double(pixelHeight))

        let cropPixelWidth = cropMaxX - cropMinX
        let cropPixelHeight = cropMaxY - cropMinY

        let scale = rep.size.width / CGFloat(pixelWidth)
        let cropPointSize = NSSize(
            width: CGFloat(cropPixelWidth) * scale,
            height: CGFloat(cropPixelHeight) * scale
        )

        logInfo("Cropping image from \(pixelWidth)*\(pixelHeight) pixels")
        logInfo("Cropped size in points: \(cropPointSize), scale: \(scale)")

        // Use Core Graphics for proper cropping without deprecated methods
        guard let cgImage = rep.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            logInfo("Failed to get CGImage representation")
            return nil
        }

        // Adjust crop rectangle to match CGImage orientation (if needed)
        let cgOriginY = cgImage.height - cropMaxY
        let cropRect = CGRect(
            x: cropMinX,
            y: cgOriginY,
            width: cropPixelWidth,
            height: cropPixelHeight
        )

        // Perform the crop using cgImage.cropping(to:)
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            logInfo("Failed to crop CGImage")
            return nil
        }

        // Create new NSImage with the cropped CGImage
        let croppedImage = NSImage(cgImage: croppedCGImage, size: cropPointSize)

        logInfo("Cropped image size: \(croppedImage.size)")

        return croppedImage
    }
}

extension NSImage {
    /// Apply a tint color to the image using Core Graphics.
    /// Uses pure Core Graphics API without deprecated methods.
    ///
    /// - Parameter color: The color to apply as a tint
    /// - Returns: A tinted version of the image, or nil if tinting fails
    func tinted(with color: NSColor) -> NSImage? {
        // Safe copy of the image
        guard let imageRep = bestRepresentation(for: .zero, context: nil, hints: nil),
              let cgImage = imageRep.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            logInfo("Failed to get CGImage representation for tinting")
            return nil
        }

        let width = cgImage.width
        let height = cgImage.height

        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else {
            logInfo("Failed to create CGContext for tinting")
            return nil
        }

        // Draw the original image
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Apply the tint color using source atop blend mode
        context.setBlendMode(.sourceAtop)
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Get the final tinted image
        guard let tintedCGImage = context.makeImage() else {
            logInfo("Failed to create tinted CGImage")
            return nil
        }

        // Get correct scale factor
        let scale = imageRep.size.width / CGFloat(imageRep.pixelsWide)
        let pointSize = NSSize(
            width: CGFloat(width) * scale,
            height: CGFloat(height) * scale
        )

        return NSImage(cgImage: tintedCGImage, size: pointSize)
    }

    // MARK: - Image Manipulation

    /// Create a new image with the specified tint color.
    ///
    /// - Parameter tintColor: The color to apply as a tint.
    /// - Returns: A new tinted image.
    func imageWithTintColor(_ tintColor: NSColor) -> NSImage? {
        guard let image = copy() as? NSImage else {
            logInfo("Failed to copy image for tinting")
            return nil
        }

        image.lockFocus()
        tintColor.set()
        let imageRect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()

        return image
    }

    // MARK: - Graphics Context Creation

    /// Create an image by drawing into a graphics context.
    ///
    /// - Parameters:
    ///   - size: The size of the image to create.
    ///   - block: A closure that receives the CGContext for drawing operations.
    /// - Returns: A new image with the drawn content.
    static func imageWithSize(_ size: CGSize, graphicsContext block: (CGContext) -> ()) -> NSImage? {
        guard size.width > 0, size.height > 0 else {
            logInfo("Invalid image size: \(size)")
            return nil
        }

        let width = Int(size.width)
        let height = Int(size.height)

        guard let bitmapImageRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: .alphaFirst,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            logInfo("Failed to create NSBitmapImageRep")
            return nil
        }

        guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmapImageRep) else {
            logInfo("Failed to create NSGraphicsContext")
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext

        block(graphicsContext.cgContext)

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: size)
        image.addRepresentation(bitmapImageRep)
        return image
    }
}
