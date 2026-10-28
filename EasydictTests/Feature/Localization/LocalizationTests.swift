//
//  LocalizationTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SwiftUI
import Testing

@testable import Easydict

@Suite("Interface Localization", .tags(.unit))
struct LocalizationTests {
    @Test("Urdu is selectable and its persisted identifier round-trips")
    func urduRegistration() {
        let language = LanguageState.LanguageType.urdu
        #expect(LanguageState.LanguageType.allCases.contains(language))
        #expect(LanguageState.LanguageType(rawValue: language.rawValue) == language)
        #expect(language.rawValue == "ur")
    }

    @Test("Regional Urdu locales use the shared interface locale", arguments: ["ur", "ur-PK", "ur-IN"])
    func regionalUrduLocale(identifier: String) {
        #expect(Locale(identifier: identifier).languageType == .urdu)
    }

    @Test("Both Urdu catalogs are included in the application bundle")
    func bundledUrduCatalogs() throws {
        let appBundle = Bundle(for: I18nHelper.self)
        let path = try #require(appBundle.path(forResource: "ur", ofType: "lproj"))
        let urduBundle = try #require(Bundle(path: path))
        #expect(urduBundle.path(forResource: "Localizable", ofType: "strings") != nil)
        #expect(urduBundle.path(forResource: "InfoPlist", ofType: "strings") != nil)
    }

    @Test("Interface layout follows the selected language")
    func interfaceLayoutDirection() {
        for language in LanguageState.LanguageType.allCases {
            let expected: LayoutDirection = language == .urdu ? .rightToLeft : .leftToRight
            #expect(language.layoutDirection == expected)
            #expect(Locale(identifier: language.rawValue).languageType == language)
        }
    }

    @Test("Query text preserves content and natural alignment", arguments: [
        "OpenAI سے ترجمہ کریں",
        "API کلید درج کریں",
        "فائل report.txt محفوظ کریں۔",
        "مزید معلومات: https://example.com",
        "قیمت 1,250.50 USD ہے۔",
        "ٹ ڈ ڑ ں ھ ہ ے",
        "English (⌘C)\nاردو متن",
        "نص عربي\nטקסט עברי",
    ])
    @MainActor
    func naturalQueryText(text: String) {
        let textView = EZTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        textView.updateTextAndParagraphStyle(text)
        #expect(textView.string == text)
        #expect(textView.alignment == .natural)
        #expect(textView.defaultParagraphStyle?.alignment == .natural)
        #expect(textView.defaultParagraphStyle?.baseWritingDirection == .natural)
    }
}
