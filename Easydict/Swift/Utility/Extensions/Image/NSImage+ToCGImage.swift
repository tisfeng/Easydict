//
//  NSImage+ToCIImage.swift
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
