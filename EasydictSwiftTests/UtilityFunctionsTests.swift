//
//  UtilityFunctionsTests.swift
//  EasydictSwiftTests
//
//  Created by AI Assistant on 2025/7/3.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Tests for utility functions and helper methods
@Suite("Utility Functions", .tags(.utilities, .unit))
struct UtilityFunctionsTests {
    @Test("AES Encryption and Decryption", .tags(.utilities))
    func testAES() {
        let text = "123"
        let encryptedText = text.encryptAES()
        let decryptedText = encryptedText.decryptAES()
        #expect(decryptedText == text)
    }

    @Test("Filter Think Tags", .tags(.utilities))
    func testFilterThinkTags() {
        let testCases: [(input: String, expected: String)] = [
            ("<think>hello", ""),
            ("<think></think>hello", "hello"),
            ("<think>hello</think>world", "world"),
            ("hello<think>world</think>", "hello<think>world</think>"),
            ("no tags here", "no tags here"),
            ("", ""),
        ]

        for (index, testCase) in testCases.enumerated() {
            let result = testCase.input.filterThinkTagContent()
            print("Test Case \(index + 1): \(result)")
            #expect(result == testCase.expected)
        }
    }
}
