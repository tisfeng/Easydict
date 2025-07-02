//
//  TestSuites.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Test suite organization for different functional areas
enum TestSuites {

    // MARK: - Test Suite Tags

    /// OCR related tests
    @Suite("OCR Text Processing", .tags(.ocr))
    struct OCRTestSuite {
        // OCR text processing tests will be automatically included
    }

    /// Apple services tests
    @Suite("Apple Services", .tags(.apple))
    struct AppleServicesSuite {
        // Apple service tests will be automatically included
    }

    /// System utilities tests
    @Suite("System Utilities", .tags(.system))
    struct SystemUtilitiesSuite {
        // System utilities tests will be automatically included
    }

    /// Utility functions tests
    @Suite("Utility Functions", .tags(.utilities))
    struct UtilitiesSuite {
        // Utility function tests will be automatically included
    }

    /// Performance and stress tests
    @Suite("Performance Tests", .tags(.performance))
    struct PerformanceTestSuite {
        // Performance tests will be automatically included
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var ocr: Self
    @Tag static var apple: Self
    @Tag static var system: Self
    @Tag static var utilities: Self
    @Tag static var performance: Self
    @Tag static var integration: Self
    @Tag static var unit: Self
}
