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
    /// - Returns: The CGImage representation of the NSImage, or nil if conversion fails.
    func toCGImage() -> CGImage? {
        guard let tiffData = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmapImage.cgImage
    }
}
