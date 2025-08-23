//
//  TestSuites.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

// MARK: - TestSuites

/// Test suite organization for different functional areas
/// This file defines common test tags and provides documentation
/// for test organization across different test files.
enum TestSuites {
    // MARK: - Test Organization Documentation

    /// OCR Text Processing Tests
    /// - Location: OCRTextProcessingTests.swift, OCRPunctuationTests.swift
    /// - Tags: .ocr + .unit (功能领域 + 测试类型)
    /// - Purpose: Tests for OCR text normalization and processing
    /// - 含义：这是关于OCR功能的单元测试

    /// Apple Services Tests
    /// - Location: AppleServiceTests.swift
    /// - Tags: .apple + .integration (功能领域 + 测试类型)
    /// - Purpose: Tests for Apple service integrations
    /// - 含义：这是关于Apple服务的集成测试

    /// Apple Language Detector Tests
    /// - Location: AppleLanguageDetectorTests.swift
    /// - Tags: .apple + .unit (功能领域 + 测试类型)
    /// - Purpose: Tests for Apple language detection with intelligent corrections
    /// - 含义：这是关于Apple语言检测功能的单元测试
    /// - Features: Pure language detection, mixed script text, short text edge cases, performance testing

    /// System Utilities Tests
    /// - Location: SystemUtilitiesTests.swift
    /// - Tags: .system + .unit (功能领域 + 测试类型)
    /// - Purpose: Tests for system utility functions
    /// - 含义：这是关于系统工具的单元测试

    /// Utility Functions Tests
    /// - Location: UtilityFunctionsTests.swift
    /// - Tags: .utilities + .unit (功能领域 + 测试类型)
    /// - Purpose: Tests for common utility functions
    /// - 含义：这是关于通用工具函数的单元测试
    ///
    /// 标签组合的逻辑：
    /// - 第一个标签通常表示"功能领域"（what - 测试什么）
    /// - 第二个标签通常表示"测试类型"（how - 怎么测试）
    /// - 例如：.utilities + .unit = 关于工具函数的单元测试
    ///
    /// 实际使用场景：
    /// 1. 只想运行所有单元测试：筛选 .unit 标签
    /// 2. 只想运行OCR相关测试：筛选 .ocr 标签
    /// 3. 只想运行OCR的单元测试：筛选 .ocr + .unit 组合
    /// 4. 运行所有集成测试：筛选 .integration 标签
    ///
    /// 测试类型说明：
    /// - .unit: 单元测试，测试单个函数，快速执行，适合开发时频繁运行
    /// - .integration: 集成测试，测试组件协作，较慢，适合完整功能验证
    /// - .performance: 性能测试，测试执行效率，适合性能优化时使用
}

// MARK: - Test Tags

extension Tag {
    // MARK: - Functional Area Tags (功能领域标签)

    /// OCR related functionality (OCR 相关功能)
    @Tag static var ocr: Self

    /// Apple service related functionality (Apple 服务相关功能)
    @Tag static var apple: Self

    /// System utility functions (系统工具函数)
    @Tag static var system: Self

    /// Utility functions (通用工具函数)
    @Tag static var utilities: Self

    // MARK: - Test Type Tags (测试类型标签)

    /// Unit tests: test individual functions/methods, fast, no external dependencies
    /// 单元测试：测试单个函数/方法，快速，无外部依赖
    @Tag static var unit: Self

    /// Integration tests: test multiple components working together, may have external dependencies, slower
    /// 集成测试：测试多个组件协作，可能有外部依赖，较慢
    @Tag static var integration: Self

    /// Performance tests: test execution speed, memory usage, etc., usually takes longer time
    /// 性能测试：测试执行速度、内存等性能指标，通常需要较长时间
    @Tag static var performance: Self
}
