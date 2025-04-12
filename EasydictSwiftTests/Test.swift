//
//  Test.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import SelectedTextKit
import Testing
import Translation

@testable import Easydict

@Test
func testSystemLanguages() async {
    systemLanguages()
}

@Test
func testAvailableIdentifiers() async {
    availableIdentifiers()
}

@available(macOS 15.0, *)
@Test
func testLanguageAvailability() async {
    let apple = AppleService()
    await apple.prepareSupportedLanguages()
}

@MainActor
@available(macOS 15.0, *)
@Test
func appleOfflineTranslation() async throws {
    let translationService = TranslationService(
        configuration: .init(
            source: .init(languageCode: .english),
            target: .init(languageCode: .chinese)
        )
    )

    #expect(try await translationService.translate(text: "Hello, world!").targetText == "你好，世界！")
    #expect(try await translationService.translate(text: "good").targetText == "利益")

    let response = try await translationService.translate(
        text: "你好",
        sourceLanguage: .init(languageCode: .chinese),
        targetLanguage: .init(languageCode: .english)
    )
    print(response)
    #expect(response.targetText == "Hello")
}

@Test
func testAES() {
    let text = "123"
    let encryptedText = text.encryptAES()
    let decryptedText = encryptedText.decryptAES()
    #expect(decryptedText == text)
}

@Test
func testAlertVolume() async throws {
    let originalVolume = try await AppleScriptTask.alertVolume()
    print("Original volume: \(originalVolume)")

    let testVolume = 50
    try await AppleScriptTask.setAlertVolume(testVolume)

    let newVolume = try await AppleScriptTask.alertVolume()
    #expect(newVolume == testVolume)

    try await AppleScriptTask.setAlertVolume(originalVolume)
    #expect(true, "Alert volume test completed")
}

@Test
func testGetSelectedText() async throws {
    // Run thousands of times to test crash.
    for i in 0 ..< 2000 {
        print("test index: \(i)")
        let selectedText = await (try? getSelectedText()) ?? ""
        print("\(i) selectedText: \(selectedText)")
    }
    #expect(true, "Test getSelectedText completed without crash")
}

@Test
func testConcurrentGetSelectedText() async throws {
    await withTaskGroup(of: Void.self) { group in
        for i in 0 ..< 2000 {
            group.addTask {
                print("test index: \(i)")
                let selectedText = (try? await getSelectedText()) ?? ""
                print("\(i) selectedText: \(selectedText)")
            }
        }
    }
    #expect(true, "Concurrent test getSelectedText completed without crash")
}

@Test
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
