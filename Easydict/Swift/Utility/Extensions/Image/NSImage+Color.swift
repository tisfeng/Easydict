//
//  NSImage+Color.swift
//  Easydict
//
//  Created by isfeng on 2025/11/17.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

extension NSImage {
    /// Reads the pixel color at a specific global point on a given screen.
    ///
    /// - Parameters:
    ///   - point: The global point (e.g., mouse position) in screen coordinates.
    ///   - screen: The `NSScreen` on which the point is located.
    /// - Returns: The `NSColor` at the specified global point, or `nil` if it cannot be determined.
    func colorAt(point: NSPoint, screen: NSScreen) -> NSColor? {
        let scale = screen.backingScaleFactor
        let screenFrame = screen.frame

        // Convert from global coordinates (bottom-left) to screen-local (top-left)
        let localX = point.x - screenFrame.minX
        let localY = screenFrame.height - (point.y - screenFrame.minY)

        // Convert logical points to physical pixels
        let pixelX = Int((localX * scale).rounded())
        let pixelY = Int((localY * scale).rounded())

        return colorAt(x: pixelX, y: pixelY)
    }

    /// Reads the pixel color at a specific pixel coordinate using a unified RGBA8 bitmap context.
    /// This guarantees correct channel ordering and returns an sRGB NSColor.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate (pixel) from the top-left origin.
    ///   - y: The y-coordinate (pixel) from the top-left origin.
    /// - Returns: The `NSColor` at the specified pixel, or `nil` if it cannot be determined.
    func colorAt(x: Int, y: Int) -> NSColor? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        // Clamp coordinates into image bounds
        let clampedX = max(0, min(x, cgImage.width - 1))
        let clampedY = max(0, min(y, cgImage.height - 1))

        // --- Create 1x1 RGBA8 bitmap context ---
        // This avoids all issues with unknown bitmap formats in CGImage.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return nil
        }

        // --- Draw the target pixel into our 1x1 context ---
        // We need to flip the y-coordinate for drawing because Core Graphics has a bottom-left origin.
        let drawY = cgImage.height - 1 - clampedY
        context.draw(cgImage, in: CGRect(
            x: -CGFloat(clampedX),
            y: -CGFloat(drawY),
            width: CGFloat(cgImage.width),
            height: CGFloat(cgImage.height)
        ))

        // --- Extract RGBA components ---
        guard let data = context.data else { return nil }
        let buffer = data.bindMemory(to: UInt8.self, capacity: 4)

        let red = CGFloat(buffer[0]) / 255.0
        let green = CGFloat(buffer[1]) / 255.0
        let blue = CGFloat(buffer[2]) / 255.0
        let alpha = CGFloat(buffer[3]) / 255.0

        // Create NSColor in sRGB for consistency with UI & HEX output
        let color = NSColor(
            calibratedRed: red, green: green, blue: blue, alpha: alpha
        ).usingColorSpace(.sRGB)

        return color
    }
}
