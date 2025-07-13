//
//  NSPasteboard+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/13.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension NSPasteboard {
    /// Gets an image from the pasteboard, correctly handling both
    /// image data and file copies (e.g., from Finder).
    ///
    /// This method prioritizes reading file URLs from the pasteboard. If image files
    /// are found, it loads the first one. If no files are found, it falls back
    /// to reading raw image data directly.
    ///
    /// - Returns: An `NSImage` object if a valid image could be retrieved, otherwise `nil`.
    @objc
    func getImage() -> NSImage? {
        // Check if there are file URLs in the pasteboard.
        if let fileURLs = readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstFileURL = fileURLs.first {
            // Attempt to create an NSImage from the file URL.
            if let image = NSImage(contentsOf: firstFileURL), image.isValid {
                print("Successfully loaded image directly from URL: \(firstFileURL)")
                return image
            }
        }

        // If no file URLs were found, try to read raw image data.
        if let image = NSImage(pasteboard: self), image.isValid {
            return image
        }
        return nil
    }
}
