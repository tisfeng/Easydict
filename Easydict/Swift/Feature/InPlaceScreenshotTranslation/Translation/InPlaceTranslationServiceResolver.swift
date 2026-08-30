//
//  InPlaceTranslationServiceResolver.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - InPlaceTranslationServiceOption

/// A configured Fixed Window service eligible for section-level translation.
struct InPlaceTranslationServiceOption: Identifiable, Equatable, Sendable {
    let identifier: String
    let displayName: String

    var id: String {
        identifier
    }
}

// MARK: - InPlaceTranslationServiceResolution

/// Distinguishes a valid saved selection from a deleted-service fallback.
struct InPlaceTranslationServiceResolution: Equatable, Sendable {
    let identifier: String?
    let shouldResetStoredSelection: Bool
}

// MARK: - InPlaceTranslationServiceResolving

/// Supplies eligible service metadata and language support to in-place UI.
/// The protocol keeps configuration-driven view-model behavior deterministic
/// without exposing provider request construction to that layer.
protocol InPlaceTranslationServiceResolving {
    func options() -> [InPlaceTranslationServiceOption]

    func resolveSelection(
        _ storedIdentifier: String,
        availableOptions: [InPlaceTranslationServiceOption]
    )
        -> InPlaceTranslationServiceResolution

    func supportedLanguages(identifier: String) -> [Language]
}

// MARK: - InPlaceTranslationServiceResolver

/// Resolves one stable, configured translation service without treating request
/// errors as configuration deletion.
final class InPlaceTranslationServiceResolver: @unchecked Sendable {
    // MARK: Lifecycle

    init(storage: LocalStorage = .shared(), factory: QueryServiceFactory = .shared) {
        self.storage = storage
        self.factory = factory
    }

    // MARK: Internal

    /// Returns current Fixed Window services that support translation or sentences.
    func options() -> [InPlaceTranslationServiceOption] {
        storage.enabledServices(.fixed).compactMap { service in
            guard isEligible(service) else { return nil }
            let identifier = service.serviceTypeWithUniqueIdentifier()
            let displayName = factory.metadata(withTypeId: identifier)?.title ?? service.name()
            return InPlaceTranslationServiceOption(
                identifier: identifier,
                displayName: displayName
            )
        }
    }

    /// Resolves persisted selection and flags only a missing configuration for reset.
    func resolveSelection(_ storedIdentifier: String) -> InPlaceTranslationServiceResolution {
        resolveSelection(storedIdentifier, availableOptions: options())
    }

    /// Pure overload used by settings and deterministic behavior tests.
    func resolveSelection(
        _ storedIdentifier: String,
        availableOptions: [InPlaceTranslationServiceOption]
    )
        -> InPlaceTranslationServiceResolution {
        if availableOptions.contains(where: { $0.identifier == storedIdentifier }) {
            return InPlaceTranslationServiceResolution(
                identifier: storedIdentifier,
                shouldResetStoredSelection: false
            )
        }
        return InPlaceTranslationServiceResolution(
            identifier: availableOptions.first?.identifier,
            shouldResetStoredSelection: true
        )
    }

    /// Creates a fresh configured instance for one block request.
    func makeService(identifier: String) -> QueryService? {
        guard options().contains(where: { $0.identifier == identifier }),
              let service = storage.service(identifier, windowType: .fixed),
              isEligible(service)
        else {
            return nil
        }
        configureForInPlaceRequest(service)
        return service
    }

    /// Ensures transient OCR source text and translation output cannot enter a provider's
    /// optional plaintext debug log. The setting belongs to this fresh service instance only.
    func configureForInPlaceRequest(_ service: QueryService) {
        service.windowType = .fixed
        service.allowsPlaintextRequestLogging = false
    }

    /// Returns the provider's explicit target-language choices.
    func supportedLanguages(identifier: String) -> [Language] {
        guard let service = makeService(identifier: identifier) else { return [] }
        return service.languages().filter { $0 != .auto }
    }

    /// Restricts the picker to actual translation providers. AI tools may inherit
    /// StreamService's translation toggle but have non-translation prompt semantics.
    func isEligible(_ service: QueryService) -> Bool {
        guard service.enabledQuery else { return false }
        let type = service.serviceType()
        guard type != .appleDictionary,
              type != .mDict,
              type != .summary,
              type != .polishing
        else {
            return false
        }

        let supported = service.supportedQueryType()
        let supportsTranslation = supported.contains(.translation) || supported.contains(.sentence)
        return supportsTranslation && service.serviceUsageStatus() != .alwaysOff
    }

    // MARK: Private

    private let storage: LocalStorage
    private let factory: QueryServiceFactory
}

// MARK: InPlaceTranslationServiceResolving

extension InPlaceTranslationServiceResolver: InPlaceTranslationServiceResolving {}
