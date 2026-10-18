//
//  OCRQRCodeTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/23.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Testing

@testable import Easydict

// MARK: - OCRQRCodeTests

/// Tests for QR code payload recognition in `AppleOCREngine`.
///
/// The fixtures are rendered in memory, so these cases stay independent from the
/// bundled OCR image samples.
@Suite("Apple OCR Engine QR Code Tests", .tags(.ocr, .integration))
struct OCRQRCodeTests {
    // MARK: Internal

    /// OCR engine instance for testing
    let ocrEngine = AppleOCREngine()

    // MARK: - QR Code Tests

    @Test("QR-only OCR returns the decoded payload", .tags(.ocr))
    func testQRCodeOnlyOCR() async throws {
        let payload = "https://github.com/tisfeng/Easydict/issues/967"
        let image = try makeOCRImage(qrPayloads: [payload])

        let result = try await ocrEngine.recognizeText(image: image, language: .english)

        #expect(result.texts.filter { $0 == payload }.count == 1)
        #expect(result.mergedText.components(separatedBy: "\n").contains(payload))
    }

    @Test("OCR appends a QR payload after recognized text", .tags(.ocr))
    func testTextAndQRCodeOCR() async throws {
        let visibleText = "Easydict mixed OCR"
        let payload = "easydict://qr/mixed-content"
        let image = try makeOCRImage(text: visibleText, qrPayloads: [payload])

        let result = try await ocrEngine.recognizeText(image: image, language: .english)

        #expect(result.mergedText.contains(visibleText))
        #expect(result.texts.last == payload)
    }

    @Test("OCR keeps multiple QR payloads and removes duplicates", .tags(.ocr))
    func testMultipleAndDuplicateQRCodes() async throws {
        let firstPayload = "https://easydict.app/first"
        let secondPayload = "https://easydict.app/second"
        let image = try makeOCRImage(
            qrPayloads: [firstPayload, firstPayload, secondPayload]
        )

        let result = try await ocrEngine.recognizeText(image: image, language: .english)

        #expect(result.texts.filter { $0 == firstPayload }.count == 1)
        #expect(result.texts.filter { $0 == secondPayload }.count == 1)
    }

    @Test("OCR without QR codes preserves the recognized text", .tags(.ocr))
    func testOCRWithoutQRCode() async throws {
        let sample = OCRTestSample.enText1
        let image = try NSImage.loadTestImage(named: sample.imageName)

        let result = try await ocrEngine.recognizeText(image: image, language: .english)

        #expect(result.mergedText == sample.expectedText)
    }

    // MARK: Private

    /// Builds a high-contrast image containing optional text and one or more QR codes.
    private func makeOCRImage(text: String? = nil, qrPayloads: [String]) throws -> NSImage {
        let qrCodeSide: CGFloat = 320
        let spacing: CGFloat = 48
        let textWidth: CGFloat = text == nil ? 0 : 620
        let imageWidth = max(
            640,
            80 + textWidth + CGFloat(qrPayloads.count) * (qrCodeSide + spacing)
        )
        let imageSize = NSSize(width: imageWidth, height: 480)
        let qrCodeImages = try qrPayloads.map {
            try makeQRCodeImage(payload: $0, side: qrCodeSide)
        }

        return NSImage(size: imageSize, flipped: false) { imageRect in
            NSColor.white.setFill()
            imageRect.fill()

            if let text {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 52, weight: .medium),
                    .foregroundColor: NSColor.black,
                ]
                NSString(string: text).draw(
                    in: NSRect(x: 40, y: 180, width: textWidth - 40, height: 120),
                    withAttributes: attributes
                )
            }

            for (index, qrCodeImage) in qrCodeImages.enumerated() {
                let originX = 40 + textWidth + CGFloat(index) * (qrCodeSide + spacing)
                qrCodeImage.draw(
                    in: NSRect(x: originX, y: 80, width: qrCodeSide, height: qrCodeSide),
                    from: .zero,
                    operation: .copy,
                    fraction: 1,
                    respectFlipped: false,
                    hints: [.interpolation: NSImageInterpolation.none]
                )
            }

            return true
        }
    }

    /// Produces a pixel-aligned QR code image for Vision integration tests.
    private func makeQRCodeImage(payload: String, side: CGFloat) throws -> NSImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        let outputImage = try #require(filter.outputImage)

        let scale = floor(side / outputImage.extent.width)
        let scaledImage = outputImage.transformed(
            by: CGAffineTransform(scaleX: scale, y: scale)
        )
        let context = CIContext(options: [.useSoftwareRenderer: true])

        let cgImage = try #require(
            context.createCGImage(scaledImage, from: scaledImage.extent)
        )

        return NSImage(cgImage: cgImage, size: NSSize(width: side, height: side))
    }
}
