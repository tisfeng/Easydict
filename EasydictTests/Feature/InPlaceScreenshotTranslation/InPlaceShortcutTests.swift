//
//  InPlaceShortcutTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Testing

@testable import Easydict

/// Verifies the non-invasive shortcut contract for in-place screenshot translation.
@Suite("In-place Translation Shortcut", .serialized, .tags(.inPlaceTranslation, .unit))
struct InPlaceShortcutTests {
    @Test("Registers one global action with no default key combination")
    func registersGlobalActionWithoutDefaultShortcut() {
        Defaults.reset(.inPlaceScreenshotTranslationShortcut)

        let action = ShortcutAction.inPlaceScreenshotTranslation

        #expect(action.isGlobal)
        #expect(ShortcutAction.globalActions.filter { $0 == action }.count == 1)
        #expect(action.localizedStringKey() == "in_place_screenshot_translation.menu.title")
        #expect(action.defaultsKey != nil)
        #expect(Defaults[.inPlaceScreenshotTranslationShortcut] == nil)
    }
}
