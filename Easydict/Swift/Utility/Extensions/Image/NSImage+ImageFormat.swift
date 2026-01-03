//
//  NSImage+ImageFormat.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/16.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit

// MARK: - ImageFormat

/// Image format for saving images
public enum ImageFormat {
    case png
    case jpeg

    // MARK: Public

    /// The file extension for this image format
    public var fileExtension: String {
        switch self {
        case .png:
            return "png"
        case .jpeg:
            return "jpg"
        }
    }
}

@objc
extension NSImage {
    // MARK: - Public APIs

    /// Save the image to the Downloads directory as PNG.
    @discardableResult
    func saveToDownloads(fileName: String? = nil) -> Bool {
        let name = fileName ?? timestampFileName() + ".png"
        let imageURL = URL.downloadsDirectory.appending(path: name)
        let scuccess = write(to: imageURL, using: .png)
        if scuccess {
            print("✅ Result saved to Downloads: \(name)")
        } else {
            print("⚠️ Failed to save result: \(name)")
        }
        return scuccess
    }

    /// Generate image filename with timestamp.
    ///
    /// - Returns: Filename `Airy_Screenshot_2025-10-27_15.19.39.022`
    func timestampFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH.mm.ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "Airy_Screenshot_\(timestamp)"
        return filename
    }

    /// Write the image to a file using the specified format.
    ///
    /// - Parameters:
    ///   - url: The file URL to write to.
    ///   - format: The image format to use (PNG or JPEG).
    ///   - compressionFactor: JPEG compression quality (only used for JPEG format). Default is 0.8.
    /// - Returns: True if successful, false otherwise.
    @nonobjc
    @discardableResult
    func write(to url: URL, using format: ImageFormat, compressionFactor: CGFloat = 0.8) -> Bool {
        let imageData: Data?

        switch format {
        case .png:
            imageData = pngData()
        case .jpeg:
            imageData = jpegData(compressionFactor: compressionFactor)
        }

        return write(imageData, to: url)
    }

    /// Write the image to the system clipboard as PNG.
    ///
    /// The image is converted to PNG and written to the clipboard. This preserves transparency,
    /// provides lossless quality, and ensures maximum compatibility with web applications.
    ///
    /// - Returns: True if successful, false otherwise.
    @discardableResult
    func writeToPasteboard() -> Bool {
        guard let pngData = pngData() else {
            logInfo("Failed to get PNG data for pasteboard")
            return false
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        guard pasteboard.setData(pngData, forType: .png) else {
            logInfo("Failed to write PNG data to pasteboard")
            return false
        }

        logInfo("Image successfully written to pasteboard as PNG")
        return true
    }

    // MARK: - Image Data Methods

    /// PNG representation of the image.
    ///
    /// Converts the NSImage to PNG data using TIFF representation as intermediate format.
    ///
    /// - Returns: PNG data if conversion succeeds, nil otherwise.
    func pngData() -> Data? {
        data(for: .png)
    }

    /// JPEG representation of the image with default compression.
    ///
    /// Converts the NSImage to JPEG data using TIFF representation as intermediate format.
    /// Uses compression factor of 0.8 for a good balance between quality and file size.
    ///
    /// - Parameter compressionFactor: JPEG compression quality, ranging from 0.0 (maximum compression) to 1.0 (maximum quality). Default is 0.8.
    /// - Returns: JPEG data if conversion succeeds, nil otherwise.
    func jpegData(compressionFactor: CGFloat = 0.8) -> Data? {
        data(for: .jpeg, compressionFactor: compressionFactor)
    }

    // MARK: - Private Helper Methods

    /// Unified data conversion method for both PNG and JPEG formats.
    ///
    /// - Parameters:
    ///   - format: The image format.
    ///   - compressionFactor: JPEG compression quality (only used for JPEG format).
    /// - Returns: Image data if conversion succeeds, nil otherwise.
    @nonobjc
    private func data(for format: NSBitmapImageRep.FileType, compressionFactor: CGFloat? = nil) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            logInfo("Failed to generate \(format) data from NSImage")
            return nil
        }

        var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]
        if let compressionFactor = compressionFactor {
            properties[.compressionFactor] = compressionFactor
        }

        guard let data = bitmapImage.representation(using: format, properties: properties) else {
            logInfo("Failed to create \(format) representation from NSImage")
            return nil
        }

        return data
    }

    /// Private helper method to write data to file with common logic
    ///
    /// - Parameters:
    ///   - url: The file URL to write to
    ///   - data: The data to write
    /// - Returns: True if successful, false otherwise
    private func write(_ data: Data?, to url: URL) -> Bool {
        guard let data else {
            logInfo("No image data to write")
            return false
        }

        let directory = url.deletingLastPathComponent()
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logInfo("Failed to create directory: \(error)")
                return false
            }
        }

        do {
            try data.write(to: url, options: .atomic)
            return true
        } catch {
            logInfo("Failed to write file: \(error)")
            return false
        }
    }
}
