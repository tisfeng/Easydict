//
//  NSImage+Export.swift
//  Easydict
//
//  Created by Easydict on 2025/11/25.
//  Copyright © 2025 izual. All rights reserved.
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
    /// Get PNG representation of the image (modern API).
    ///
    /// - Returns: PNG data, or nil if conversion fails
    ///
    /// - Example:
    /// ```swift
    /// if let pngData = image.pngData {
    ///     try? pngData.write(to: fileURL)
    /// }
    /// ```
    var pngData: Data? {
        guard let tiffData = tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return imageRep.representation(using: .png, properties: [:])
    }

    /// Get PNG representation of the image (legacy mm_ API for Objective-C compatibility).
    ///
    /// - Returns: PNG data, or nil if conversion fails
    @objc(mm_PNGData)
    var mm_PNGData: Data? {
        pngData
    }

    /// Get JPEG representation of the image (modern API).
    ///
    /// - Parameter compressionFactor: JPEG compression quality (0.0-1.0), defaults to 1.0 (no compression)
    /// - Returns: JPEG data, or nil if conversion fails
    ///
    /// - Example:
    /// ```swift
    /// // Maximum quality
    /// let jpegData = image.jpegData()
    ///
    /// // Compressed
    /// let compressedData = image.jpegData(compressionFactor: 0.8)
    /// ```
    func jpegData(compressionFactor: CGFloat = 1.0) -> Data? {
        guard let tiffData = tiffRepresentation,
              let imageRep = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return imageRep.representation(
            using: .jpeg,
            properties: [.compressionFactor: compressionFactor]
        )
    }

    /// Get JPEG representation of the image (legacy mm_ API).
    ///
    /// - Returns: JPEG data with maximum quality, or nil if conversion fails
    @objc(mm_JPEGData)
    var mm_JPEGData: Data? {
        jpegData(compressionFactor: 1.0)
    }

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
    func mm_writeToFileAsPNG(_ path: String) -> Bool {
        (try? savePNG(toPath: path)) != nil
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
        (try? saveJPEG(toPath: path)) != nil
    }

    /// Save image to file as PNG format (throwing version).
    ///
    /// Creates intermediate directories if needed.
    ///
    /// - Parameter path: Target file path
    /// - Throws: `ImageExportError` if save fails
    ///
    /// - Example:
    /// ```swift
    /// do {
    ///     try image.savePNG(toPath: "/path/to/image.png")
    /// } catch {
    ///     print("Failed to save: \(error)")
    /// }
    /// ```
    func savePNG(toPath path: String) throws {
        guard !path.isEmpty else {
            throw ImageExportError.invalidPath
        }

        guard let data = pngData else {
            throw ImageExportError.noImageData
        }

        try ensureDirectoryExists(for: path)

        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            throw ImageExportError.writeFailed
        }
    }

    /// Save image to file as JPEG format (throwing version).
    ///
    /// Creates intermediate directories if needed.
    ///
    /// - Parameters:
    ///   - path: Target file path
    ///   - compressionFactor: JPEG compression quality (0.0-1.0), defaults to 1.0
    /// - Throws: `ImageExportError` if save fails
    ///
    /// - Example:
    /// ```swift
    /// try image.saveJPEG(toPath: "/path/to/image.jpg", compressionFactor: 0.9)
    /// ```
    func saveJPEG(toPath path: String, compressionFactor: CGFloat = 1.0) throws {
        guard !path.isEmpty else {
            throw ImageExportError.invalidPath
        }

        guard let data = jpegData(compressionFactor: compressionFactor) else {
            throw ImageExportError.noImageData
        }

        try ensureDirectoryExists(for: path)

        do {
            try data.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            throw ImageExportError.writeFailed
        }
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
