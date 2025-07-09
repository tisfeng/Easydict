//
//  NSImage+Test.swift
//  EasydictSwiftTests
//
//  Created by tisfeng on 2025/7/8.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation
import Vision

@testable import Easydict

// MARK: - NSImage+Test

/// Testing utilities for NSImage and OCR functionality
///
/// This extension provides convenient methods for loading test images and performing
/// OCR operations in unit tests. It centralizes common test functionality to avoid
/// code duplication across different test suites.
extension NSImage {
    // MARK: - Bundle Access

    /// Test images directory path
    ///
    /// `Bundle(for:)` requires a class (`AnyClass`) argument, but test structs
    /// cannot be used directly. We introduce a private dummy class `BundleLocator`
    /// solely to obtain the correct unit‑test bundle.
    private class BundleLocator {}

    private static var testBundle: Bundle {
        Bundle(for: BundleLocator.self)
    }

    // MARK: - Image Loading

    /// Load test image from bundle
    /// - Parameter imageName: Name of the image file in Resources directory
    /// - Returns: NSImage instance or nil if loading fails
    static func loadTestImage(named imageName: String) -> NSImage? {
        guard let imagePath = testBundle.path(
            forResource: imageName.components(separatedBy: ".").first,
            ofType: imageName.components(separatedBy: ".").last
        )
        else {
            print("❌ Could not find image path for: \(imageName)")
            return nil
        }

        guard let image = NSImage(contentsOfFile: imagePath) else {
            print("❌ Could not load image from path: \(imagePath)")
            return nil
        }

        print("✅ Loaded image: \(imageName) from \(imagePath)")
        return image
    }

    // MARK: - OCR Integration

    /// Load test image and perform OCR to get real text observations
    /// - Parameters:
    ///   - imageName: Name of the image file in Resources directory
    ///   - language: Target language for OCR recognition (defaults to .auto)
    /// - Returns: Tuple containing the image and OCR observations, or nil if loading fails
    static func loadTestImageWithOCR(
        named imageName: String,
        language: Language = .auto
    ) async
        -> (NSImage, [VNRecognizedTextObservation])? {
        guard let image = loadTestImage(named: imageName) else {
            return nil
        }

        guard let cgImage = image.toCGImage() else {
            print("❌ Could not convert NSImage to CGImage")
            return nil
        }

        do {
            let ocrEngine = AppleOCREngine()
            let observations = try await ocrEngine.recognizeTextAsync(
                cgImage: cgImage, language: language
            )
            print("✅ Loaded image: \(imageName) with \(observations.count) text observations")
            return (image, observations)
        } catch {
            print("❌ OCR failed for image: \(imageName), error: \(error)")
            return nil
        }
    }

    // MARK: - Predefined Test Data

    /// Load commonly used test image with OCR for English text recognition
    /// - Returns: Tuple containing the image and OCR observations for "ocr-en-text-1.png"
    static func loadDefaultEnglishTestImageWithOCR() async -> (
        NSImage, [VNRecognizedTextObservation]
    )? {
        await loadTestImageWithOCR(named: "ocr-en-text-1.png", language: .english)
    }

    /// Load commonly used test image with OCR and create metrics
    /// - Returns: Tuple containing the image, observations, and metrics for "ocr-en-text-1.png"
    static func loadDefaultEnglishTestDataWithMetrics() async -> OCRMetrics? {
        guard let (image, observations) = await loadDefaultEnglishTestImageWithOCR() else {
            return nil
        }

        let metrics = OCRMetrics(
            ocrImage: image, language: .english, textObservations: observations
        )
        return metrics
    }

    // MARK: - Mock Data Creation

    /// Create a simple test image for unit testing
    /// - Parameter size: Size of the image to create
    /// - Returns: NSImage instance for testing
    static func createTestImage(size: NSSize = NSSize(width: 100, height: 100)) -> NSImage {
        NSImage(size: size)
    }
}
