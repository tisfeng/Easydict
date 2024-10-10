//
//  Test.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing

@testable import Easydict

@Test func checkName() {
    #expect(1 + 2 == 3)

    printAllAvailableLanguages()
}

@available(macOS 15.0, *)
@Test func supportedLanguages() async {
    prepareSupportedLanguages()
}

@MainActor
@available(macOS 15.0, *)
@Test func translation() async throws {
    let translationService = TranslationService()
    let response = try await translationService.translate(
        text: "Hello, world!",
        sourceLanguage: .init(identifier: "en"),
        targetLanguage: .init(identifier: "zh")
    )
    print(response)

    #expect(response.targetText == "你好，世界！")
}
