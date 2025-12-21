//
//  ServiceTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2025/12/20.
//  Copyright © 2025 izual. All rights reserved.
//

import Testing

@testable import Easydict

/// Integration tests that verify each registered service can translate a sample input.
@Suite("Service Translation Validation", .tags(.integration))
struct ServiceTests {
    // MARK: Internal

    /// Validates that every registered service returns a successful translation result.
    @Test("Validate All Services Translation", .tags(.integration))
    func testAllServicesValidateTranslation() async throws {
        let factory = QueryServiceFactory.shared
        let serviceTypes = factory.allServiceTypes

        #expect(!serviceTypes.isEmpty, "QueryServiceFactory returned no registered services.")

        for serviceType in serviceTypes {
            try await validate(serviceType: serviceType, factory: factory)
        }
    }

    // MARK: Private

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
