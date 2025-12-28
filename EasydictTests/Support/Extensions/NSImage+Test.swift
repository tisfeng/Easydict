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

    /// Load test image from test bundle resources
    /// - Parameters:
    ///   - imageName: Name of the image file in the bundle
    ///   - subdirectory: Resource subdirectory relative to the test bundle
    /// - Returns: NSImage instance or nil if loading fails
    static func loadTestImage(named imageName: String, subdirectory: String = "OCRImages") -> NSImage? {
        let baseName = (imageName as NSString).deletingPathExtension
        let fileExtension = (imageName as NSString).pathExtension

        let imageURL = testBundle.url(
            forResource: baseName,
            withExtension: fileExtension,
            subdirectory: subdirectory
        ) ?? testBundle.url(forResource: baseName, withExtension: fileExtension)

        guard let imageURL else {
            print("❌ Could not find image path for: \(imageName)")
            return nil
        }

        guard let image = NSImage(contentsOf: imageURL) else {
            print("❌ Could not load image from path: \(imageURL.path)")
            return nil
        }

        print("✅ Loaded image: \(imageName) from \(imageURL.path)")
        return image
    }
}
