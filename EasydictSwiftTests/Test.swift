//
//  Test.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing
import Translation

@testable import Easydict

@Test func testSystemLanguages() async {
    systemLanguages()
}

@Test func testAvailableIdentifiers() async {
    availableIdentifiers()
}

@available(macOS 15.0, *)
@Test func testLanguageAvailability() async {
    let apple = AppleService()
    await apple.prepareSupportedLanguages()
}

@MainActor
@available(macOS 15.0, *)
@Test func appleOfflineTranslation() async throws {
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

@Test func testAES() {
    let text = "123"
    let encryptedText = text.encryptAES()
    let decryptedText = encryptedText.decryptAES()
    #expect(decryptedText == text)
}

@Test func alertVolume() async throws {
    let volume = try await AppleScriptTask.alertVolume()
    print(volume)
}

@Test func setAlertVolume() async throws {
    try await AppleScriptTask.setAlertVolume(50)
}
