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
}
