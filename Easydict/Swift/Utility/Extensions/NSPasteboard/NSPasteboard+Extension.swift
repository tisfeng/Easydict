//
//  NSPasteboard+Extension.swift
//  Easydict
//
//  Created by tisfeng on 2025/7/13.
//  Copyright © 2025 izual. All rights reserved.
//

import CoreGraphics
import Foundation

extension NSPasteboard {
    /// Get text from pasteboard
    @objc
    func readString() -> String? {
        string(forType: .string)
    }

    // MARK: - Get Image from Pasteboard

    /// Gets an image from the pasteboard, correctly handling both
    /// image data and file copies (e.g., from Finder).
    ///
    /// This method prioritizes reading file URLs from the pasteboard. If image files
    /// are found, it loads the first one. If no files are found, it falls back
    /// to reading raw image data directly.
    ///
    /// - Returns: An `NSImage` object if a valid image could be retrieved, otherwise `nil`.
    @objc
    func readImage() -> NSImage? {
        print("=== NSPasteboard.getImage() Debug ===")

        /**
         NSPasteboard.types are different depending on the copied content on pasteboard.

         For PDF image:

         [__C.NSPasteboardType(_rawValue: com.adobe.pdf), __C.NSPasteboardType(_rawValue: Apple PDF pasteboard type), __C.NSPasteboardType(_rawValue: public.tiff), __C.NSPasteboardType(_rawValue: NeXT TIFF v4.0 pasteboard type)]
         */

        let availableTypes = types ?? []
//        print("Available pasteboard types: \(availableTypes)\n")

        // 1. Check if there are file URLs in the pasteboard (highest priority)
        if let fileURLs = readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstFileURL = fileURLs.first {
            print("Found file URL: \(firstFileURL)")
            if let image = NSImage(contentsOf: firstFileURL), image.isValid {
                print("Successfully loaded image directly from the URL")
                print("Image size: \(image.size)")
                print("Image representations: \(image.representations)")
                return image
            } else {
                print("Failed to load image from URL: \(firstFileURL)")
            }
        }

        // 2. Try to handle PDF data specifically (better background handling)
        if availableTypes.contains(.pdf) {
            if let pdfData = data(forType: .pdf) {
                print("Found PDF data in pasteboard, size: \(pdfData.count) bytes")
                if let image = createImageFromPDFData(pdfData) {
                    print("Successfully created image from PDF data")
                    return image
                }
            }
        }

        // 3. Try Apple PDF pasteboard type (fallback for specific apps)
        if let applePDFType = availableTypes.first(where: {
            $0.rawValue == "Apple PDF pasteboard type"
        }),
            let pdfData = data(forType: applePDFType) {
            print("Found Apple PDF data in pasteboard, size: \(pdfData.count) bytes")
            if let image = createImageFromPDFData(pdfData) {
                print("Successfully created image from Apple PDF data")
                return image
            }
        }

        // 4. Try TIFF data (often preserves better quality)
        if availableTypes.contains(.tiff) {
            if let tiffData = data(forType: .tiff),
               let image = NSImage(data: tiffData), image.isValid {
                print("Successfully loaded image from TIFF data")
                print("Image size: \(image.size)")
                return image
            }
        }

        // 5. Try PNG data
        if availableTypes.contains(.png) {
            if let pngData = data(forType: .png),
               let image = NSImage(data: pngData), image.isValid {
                print("Successfully loaded image from PNG data")
                print("Image size: \(image.size)")
                return image
            }
        }

        // 6. Last resort: try generic NSImage(pasteboard:)
        if let image = NSImage(pasteboard: self), image.isValid {
            print("Successfully loaded image from pasteboard using generic method")
            print("Image size: \(image.size)")
            print("Image representations: \(image.representations)")
            for (index, rep) in image.representations.enumerated() {
                print("  Rep \(index): \(type(of: rep)) - \(rep)")
            }
            return image
        }

        print("Failed to load any image from pasteboard")
        return nil
    }

    /// Creates an NSImage from PDF data with proper white background
    private func createImageFromPDFData(_ pdfData: Data) -> NSImage? {
        guard let pdfDoc = CGPDFDocument(CGDataProvider(data: pdfData as CFData)!),
              let pdfPage = pdfDoc.page(at: 1)
        else {
            print("Failed to create PDF document from data")
            return nil
        }

        let pageRect = pdfPage.getBoxRect(.mediaBox)
        print("PDF page rect: \(pageRect)")

        // Get current screen scale factor
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        print("Using screen scale factor: \(scale)")

        let pixelWidth = Int(pageRect.width * scale)
        let pixelHeight = Int(pageRect.height * scale)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                  data: nil,
                  width: pixelWidth,
                  height: pixelHeight,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: colorSpace,
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else {
            print("Failed to create CGContext for PDF rendering")
            return nil
        }

        // Fill with white background
        context.setFillColor(CGColor.white)
        context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))

        // Scale context to match the scale factor
        context.scaleBy(x: scale, y: scale)

        // Draw PDF page
        context.drawPDFPage(pdfPage)

        guard let cgImage = context.makeImage() else {
            print("Failed to create CGImage from context")
            return nil
        }

        let nsImage = NSImage(cgImage: cgImage, size: pageRect.size)
        print("Successfully created NSImage from PDF with white background")
        print("Final image size: \(nsImage.size)")

        return nsImage
    }
}
