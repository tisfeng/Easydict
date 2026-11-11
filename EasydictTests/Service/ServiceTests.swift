//
//  ServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2025/12/20.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

// MARK: - ServiceTests

/// Integration tests that verify each registered service can translate a sample input.
@Suite("Service Translation Validation", .tags(.integration))
struct ServiceTests {
    // MARK: Internal

    @Test("Validate translation services without local setup")
    func testServicesWithoutLocalSetup() async throws {
        try await validateServices(requiringLocalEnvironment: false)
    }

    @Test("Validate translation services that require local setup", .tags(.requiresLocalEnvironment))
    func testServicesRequiringLocalEnvironment() async throws {
        try await validateServices(requiringLocalEnvironment: true)
    }

    // MARK: Private

    private func validateServices(requiringLocalEnvironment: Bool) async throws {
        let factory = QueryServiceFactory.shared
        let serviceTypes = factory.allServiceTypes.filter { serviceType in
            switch serviceType {
            case .apple, .appleDictionary, .mDict, .ollama:
                // These keyless services still rely on local assets or a local server.
                return requiringLocalEnvironment
            default:
                let apiKeyRequirement = factory.metadata(withTypeId: serviceType.rawValue)?.apiKeyRequirement
                return (apiKeyRequirement != ServiceAPIKeyRequirement.none) == requiringLocalEnvironment
            }
        }

        #expect(!serviceTypes.isEmpty, "QueryServiceFactory returned no matching services.")

        for serviceType in serviceTypes {
            try await validate(serviceType: serviceType, factory: factory)
        }
    }

    /// Validates a single service type and records a failure if translation fails.
    private func validate(serviceType: ServiceType, factory: QueryServiceFactory) async throws {
        let service = try #require(factory.service(withTypeId: serviceType.rawValue))

        let result = await validationResult(for: service)
        #expect(
            result.error == nil,
            "Service [\(serviceType.rawValue)] failed validation: \(result.error?.localizedDescription ?? "unknown error")"
        )
    }

    /// Returns the validation result for a service, using dictionary-friendly input when needed.
    private func validationResult(for service: QueryService) async -> QueryResult {
        if service is AppleDictionary {
            return await validateTranslation(
                service,
                text: "good",
                from: .english,
                to: .english
            )
        }

        return await service.validate()
    }

    /// Runs a translation request and returns the final query result.
    private func validateTranslation(
        _ service: QueryService,
        text: String,
        from: Language,
        to: Language
    ) async
        -> QueryResult {
        let currentResult = service.resetServiceResult()

        do {
            return try await service.translate(text, from: from, to: to)
        } catch {
            let result = service.result ?? currentResult
            if result.error == nil {
                result.error = QueryError.queryError(from: error)
            }
            return result
        }
    }
}
