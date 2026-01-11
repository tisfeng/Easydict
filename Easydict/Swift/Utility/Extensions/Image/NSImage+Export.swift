////
////  NSImage+Export.swift
////  Easydict
////
////  Created by Easydict on 2025/11/25.
////  Copyright © 2025 izual. All rights reserved.
////
//
import AppKit

// MARK: - ImageExportError

enum ImageExportError: Error, LocalizedError {
    case invalidPath
    case noImageData
    case directoryCreationFailed
    case writeFailed

    // MARK: Internal

    var errorDescription: String? {
        switch self {
        case .invalidPath:
            "The provided file path is invalid or empty"
        case .noImageData:
            "Failed to generate image data"
        case .directoryCreationFailed:
            "Failed to create the target directory"
        case .writeFailed:
            "Failed to write image data to file"
        }
    }
}

// MARK: - NSImage Export Extension

@objc
extension NSImage {
    /// Write image to file as PNG format (legacy mm_ API for Objective-C compatibility).
    ///
    /// - Parameter path: Target file path
    /// - Returns: `true` if successful, `false` otherwise
    ///
    /// - Note: This is a legacy method for Objective-C compatibility. Consider using `savePNG(to:)` which throws errors.
    ///
    /// - Example:
    /// ```swift
    /// let success = image.mm_writeToFileAsPNG("/path/to/image.png")
    /// ```
    @objc(mm_writeToFileAsPNG:)
    @discardableResult
    func mm_writeToFileAsPNG(_ path: String) -> Bool {
        guard let url = URL(string: path) else {
            return false
        }

        return write(to: url, using: .png)
    }

    /// Write image to file as JPEG format (legacy mm_ API for Objective-C compatibility).
    ///
    /// - Parameter path: Target file path
    /// - Returns: `true` if successful, `false` otherwise
    ///
    /// - Note: This is a legacy method for Objective-C compatibility. Consider using `saveJPEG(to:compressionFactor:)` which throws errors.
    ///
    /// - Example:
    /// ```swift
    /// let success = image.mm_writeToFileAsJPEG("/path/to/image.jpg")
    /// ```
    @objc(mm_writeToFileAsJPEG:)
    func mm_writeToFileAsJPEG(_ path: String) -> Bool {
        guard let url = URL(string: path) else {
            return false
        }

        return write(to: url, using: .jpeg)
    }

    /// Apply tint color to the image (modern API).
    ///
    /// - Parameter tintColor: Color to apply to the image
    /// - Returns: New image with tint color applied
    ///
    /// - Example:
    /// ```swift
    /// let tintedImage = originalImage.withTintColor(.red)
    /// ```
    func withTintColor(_ tintColor: NSColor) -> NSImage {
        let newImage = copy() as! NSImage
        newImage.lockFocus()
        tintColor.set()
        let imageRect = NSRect(origin: .zero, size: newImage.size)
        imageRect.fill(using: .sourceAtop)
        newImage.unlockFocus()
        return newImage
    }

    /// Apply tint color to the image (legacy API for Objective-C compatibility).
    ///
    /// - Parameter tintColor: Color to apply to the image
    /// - Returns: New image with tint color applied
    @objc(imageWithTintColor:)
    func image(withTintColor tintColor: NSColor) -> NSImage {
        withTintColor(tintColor)
    }

    /// Create an image by drawing in a graphics context (modern API).
    ///
    /// - Parameters:
    ///   - size: Size of the image to create
    ///   - draw: Closure that receives a CGContext to draw in
    /// - Returns: New image with the drawn content
    ///
    /// - Example:
    /// ```swift
    /// let image = NSImage.image(size: CGSize(width: 100, height: 100)) { context in
    ///     context.setFillColor(NSColor.red.cgColor)
    ///     context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
    /// }
    /// ```
    static func image(size: CGSize, draw: (CGContext) -> ()) -> NSImage {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bitmapFormat: .alphaFirst,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!

        let graphicsContext = NSGraphicsContext(bitmapImageRep: rep)!

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphicsContext

        draw(graphicsContext.cgContext)

        NSGraphicsContext.restoreGraphicsState()

        let newImage = NSImage(size: size)
        newImage.addRepresentation(rep)
        return newImage
    }

    /// Create an image by drawing in a graphics context (legacy mm_ API for Objective-C compatibility).
    ///
    /// - Parameters:
    ///   - size: Size of the image to create
    ///   - block: Closure that receives a CGContext to draw in
    /// - Returns: New image with the drawn content
    @objc(mm_imageWithSize:graphicsContext:)
    static func mm_image(withSize size: CGSize, graphicsContext block: (CGContext) -> ()) -> NSImage {
        image(size: size, draw: block)
    }

    // MARK: - Private Helpers

    private func ensureDirectoryExists(for path: String) throws {
        let directory = (path as NSString).deletingLastPathComponent

        guard !directory.isEmpty else {
            throw ImageExportError.invalidPath
        }

        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory) {
            do {
                try fileManager.createDirectory(
                    atPath: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                throw ImageExportError.directoryCreationFailed
            }
        }
    }
}
