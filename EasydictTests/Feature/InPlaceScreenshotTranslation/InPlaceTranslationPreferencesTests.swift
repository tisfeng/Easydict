//
//  InPlaceTranslationPreferencesTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Testing

@testable import Easydict

/// Locks down the user-facing defaults that seed each in-place translation session.
@Suite("In-place Translation Preferences", .serialized, .tags(.inPlaceTranslation, .unit))
struct InPlaceTranslationPreferencesTests {
    // MARK: Internal

    @Test("Uses live updates and pinning without preselecting a service")
    func usesSafeProductDefaults() {
        resetPreferences()
        defer { resetPreferences() }

        #expect(Defaults[.inPlaceTranslationServiceIdentifier].isEmpty)
        #expect(Defaults[.inPlaceTranslationLiveUpdatesEnabled])
        #expect(Defaults[.inPlaceTranslationPinned])
        #expect(!Defaults[.inPlaceTranslationPrivacyDisclosureAcknowledged])
    }

    @Test("Shows the privacy disclosure only until it has been acknowledged")
    func resolvesPrivacyDisclosurePresentation() {
        #expect(
            InPlaceTranslationPrivacyDisclosurePolicy.shouldPresent(
                hasAcknowledged: false
            )
        )
        #expect(
            !InPlaceTranslationPrivacyDisclosurePolicy.shouldPresent(
                hasAcknowledged: true
            )
        )
    }

    @Test("Privacy disclosure displays only a resolved provider name or generic fallback")
    func resolvesPrivacyDisclosureServiceName() {
        let options = [
            InPlaceTranslationServiceOption(identifier: "first", displayName: "First Provider"),
            InPlaceTranslationServiceOption(identifier: "saved", displayName: "Saved Provider"),
        ]

        #expect(
            InPlaceTranslationPrivacyDisclosurePolicy.serviceDisplayName(
                storedIdentifier: "saved",
                options: options,
                fallback: "Translation service"
            ) == "Saved Provider"
        )
        #expect(
            InPlaceTranslationPrivacyDisclosurePolicy.serviceDisplayName(
                storedIdentifier: "deleted",
                options: options,
                fallback: "Translation service"
            ) == "First Provider"
        )
        #expect(
            InPlaceTranslationPrivacyDisclosurePolicy.serviceDisplayName(
                storedIdentifier: "",
                options: [],
                fallback: "Translation service"
            ) == "Translation service"
        )
    }

    // MARK: Private

    private func resetPreferences() {
        Defaults.reset(.inPlaceTranslationServiceIdentifier)
        Defaults.reset(.inPlaceTranslationLiveUpdatesEnabled)
        Defaults.reset(.inPlaceTranslationPinned)
        Defaults.reset(.inPlaceTranslationPrivacyDisclosureAcknowledged)
    }
}
