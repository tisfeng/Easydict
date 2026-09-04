//
//  InPlaceTranslationServiceResolverTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

// MARK: - InPlaceTranslationServiceResolverTests

/// Verifies saved-provider resolution without contacting providers or mutating service storage.
@Suite("In-place Translation Service Resolver", .tags(.inPlaceTranslation, .unit))
struct InPlaceTranslationServiceResolverTests {
    // MARK: Internal

    @Test("Keeps an available saved service including its dynamic identifier")
    func keepsAvailableStoredSelection() {
        let dynamicIdentifier = "custom-openai:00000000-0000-4000-8000-000000000001"
        let options = [
            InPlaceTranslationServiceOption(identifier: "apple", displayName: "Apple"),
            InPlaceTranslationServiceOption(
                identifier: dynamicIdentifier,
                displayName: "Custom OpenAI"
            ),
        ]

        let resolution = InPlaceTranslationServiceResolver().resolveSelection(
            dynamicIdentifier,
            availableOptions: options
        )

        #expect(resolution.identifier == dynamicIdentifier)
        #expect(!resolution.shouldResetStoredSelection)
    }

    @Test("A deleted service falls back to the first available option and resets storage")
    func fallsBackOnlyWhenStoredServiceIsMissing() {
        let resolution = InPlaceTranslationServiceResolver().resolveSelection(
            "deleted-service",
            availableOptions: [
                InPlaceTranslationServiceOption(identifier: "first", displayName: "First"),
                InPlaceTranslationServiceOption(identifier: "second", displayName: "Second"),
            ]
        )

        #expect(resolution.identifier == "first")
        #expect(resolution.shouldResetStoredSelection)
    }

    @Test("No eligible service produces an explicit empty resolution")
    func reportsNoAvailableService() {
        let resolution = InPlaceTranslationServiceResolver().resolveSelection(
            "missing",
            availableOptions: []
        )

        #expect(resolution.identifier == nil)
        #expect(resolution.shouldResetStoredSelection)
    }

    @Test("A missing saved service falls back to the next dynamic option or clears")
    func resolvesMissingSelectionToDynamicFallbackOrEmpty() {
        let resolver = InPlaceTranslationServiceResolver()
        let dynamicIdentifier = "custom-openai:00000000-0000-4000-8000-000000000002"
        let dynamicOption = InPlaceTranslationServiceOption(
            identifier: dynamicIdentifier,
            displayName: "Dynamic Fallback"
        )

        let fallback = resolver.resolveSelection(
            "missing-service",
            availableOptions: [dynamicOption]
        )
        let cleared = resolver.resolveSelection(
            "missing-service",
            availableOptions: []
        )

        #expect(fallback.identifier == dynamicIdentifier)
        #expect(fallback.shouldResetStoredSelection)
        #expect(cleared.identifier == nil)
        #expect(cleared.shouldResetStoredSelection)
    }

    @Test("In-place requests use the fixed window and suppress plaintext logs")
    func configuresTransientRequestPrivacy() {
        let service = InPlaceConfigurationQueryService()

        InPlaceTranslationServiceResolver().configureForInPlaceRequest(service)

        #expect(service.windowType == .fixed)
        #expect(!service.allowsPlaintextRequestLogging)
    }

    @Test("Eligibility includes translators and excludes dictionary or AI-tool semantics")
    func filtersNonTranslationProviders() {
        let resolver = InPlaceTranslationServiceResolver()

        #expect(resolver.isEligible(service(type: .bing)))
        #expect(!resolver.isEligible(service(type: .appleDictionary)))
        #expect(!resolver.isEligible(service(type: .mDict)))
        #expect(!resolver.isEligible(service(type: .summary)))
        #expect(!resolver.isEligible(service(type: .polishing)))
        #expect(!resolver.isEligible(service(type: .bing, queryType: [.dictionary])))
        #expect(!resolver.isEligible(service(type: .bing, usageStatus: .alwaysOff)))
    }

    @Test("A collapsed Fixed Window result card does not remove translator eligibility")
    func keepsTranslatorEligibleWhenFixedWindowResultCardIsCollapsed() {
        let translator = service(type: .bing, enabledQuery: false)

        #expect(!translator.enabledQuery)
        #expect(InPlaceTranslationServiceResolver().isEligible(translator))
    }

    // MARK: Private

    private func service(
        type: ServiceType,
        queryType: EZQueryTextType = [.translation],
        usageStatus: EZServiceUsageStatus = .alwaysOn,
        enabledQuery: Bool = true
    )
        -> InPlaceConfigurationQueryService {
        let service = InPlaceConfigurationQueryService()
        service.configuredType = type
        service.configuredQueryType = queryType
        service.configuredUsageStatus = usageStatus
        service.configuredEnabledQuery = enabledQuery
        return service
    }
}

// MARK: - InPlaceConfigurationQueryService

/// Minimal configurable service used to inspect resolver behavior without a provider.
private final class InPlaceConfigurationQueryService: QueryService {
    override var enabledQuery: Bool {
        get { configuredEnabledQuery }
        set { configuredEnabledQuery = newValue }
    }

    var configuredType = ServiceType.bing
    var configuredQueryType: EZQueryTextType = [.translation]
    var configuredUsageStatus = EZServiceUsageStatus.alwaysOn
    var configuredEnabledQuery = true

    override func serviceType() -> ServiceType {
        configuredType
    }

    override func supportedQueryType() -> EZQueryTextType {
        configuredQueryType
    }

    override func serviceUsageStatus() -> EZServiceUsageStatus {
        configuredUsageStatus
    }
}
