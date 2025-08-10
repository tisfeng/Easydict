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
        // First try direct conversion
        var rect = CGRect(origin: .zero, size: size)
        if let cgImage = cgImage(forProposedRect: &rect, context: nil, hints: nil) {
            return cgImage
        }

        // Fallback to TIFF representation
        if let tiffData = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffData) {
            return bitmapImage.cgImage
        }

        return nil
    }
}
