//
//  test.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/9.
//  Copyright © 2024 izual. All rights reserved.
//

import Testing
@testable import Easydict

@Test func checkName() {
    #expect(1+2 == 3)

    printAllAvailableLanguages()
}


@available(macOS 15.0, *)
@Test func supportedLanguages() async {
    await prepareSupportedLanguages()
}
