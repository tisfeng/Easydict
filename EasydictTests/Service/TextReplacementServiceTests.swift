//
//  TextReplacementServiceTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/25.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation
import Testing

@testable import Easydict

/// Unit tests for replacement-action defaults, service selection, and prompt isolation.
@Suite("Text Replacement Services", .serialized, .tags(.unit))
struct TextReplacementServiceTests {
    // MARK: Internal

    @Test("Defaults preserve the existing built-in action behavior")
    func defaultsPreserveExistingBuiltInBehavior() {
        let previousTranslateService = Defaults[.translateAndReplaceServiceIdentifier]
        let previousPolishService = Defaults[.polishAndReplaceServiceIdentifier]
        let previousTranslatePrompt = Defaults[.translateAndReplaceAdditionalPrompt]
        let previousPolishPrompt = Defaults[.polishAndReplaceAdditionalPrompt]
        defer {
            Defaults[.translateAndReplaceServiceIdentifier] = previousTranslateService
            Defaults[.polishAndReplaceServiceIdentifier] = previousPolishService
            Defaults[.translateAndReplaceAdditionalPrompt] = previousTranslatePrompt
            Defaults[.polishAndReplaceAdditionalPrompt] = previousPolishPrompt
        }

        Defaults.reset(.translateAndReplaceServiceIdentifier)
        Defaults.reset(.polishAndReplaceServiceIdentifier)
        Defaults.reset(.translateAndReplaceAdditionalPrompt)
        Defaults.reset(.polishAndReplaceAdditionalPrompt)

        #expect(Defaults[.translateAndReplaceServiceIdentifier] == ServiceType.builtInAI.rawValue)
        #expect(Defaults[.polishAndReplaceServiceIdentifier] == ServiceType.polishing.rawValue)
        #expect(Defaults[.translateAndReplaceAdditionalPrompt].isEmpty)
        #expect(Defaults[.polishAndReplaceAdditionalPrompt].isEmpty)
        #expect(TextReplacementAction.translate.defaultServiceIdentifier == ServiceType.builtInAI.rawValue)
        #expect(TextReplacementAction.polish.defaultServiceIdentifier == ServiceType.polishing.rawValue)
    }

    @Test("Translation and polishing additional requirements remain independent")
    func additionalRequirementDefaultsRemainIndependent() {
        let previousTranslatePrompt = Defaults[.translateAndReplaceAdditionalPrompt]
        let previousPolishPrompt = Defaults[.polishAndReplaceAdditionalPrompt]
        defer {
            Defaults[.translateAndReplaceAdditionalPrompt] = previousTranslatePrompt
            Defaults[.polishAndReplaceAdditionalPrompt] = previousPolishPrompt
        }

        Defaults[.translateAndReplaceAdditionalPrompt] = "Initial translation requirement"
        Defaults[.polishAndReplaceAdditionalPrompt] = "Initial polishing requirement"

        Defaults[.translateAndReplaceAdditionalPrompt] = "Translate with concise terminology"
        #expect(Defaults[.translateAndReplaceAdditionalPrompt] == "Translate with concise terminology")
        #expect(Defaults[.polishAndReplaceAdditionalPrompt] == "Initial polishing requirement")

        Defaults[.polishAndReplaceAdditionalPrompt] = "Polish with a formal tone"
        #expect(Defaults[.translateAndReplaceAdditionalPrompt] == "Translate with concise terminology")
        #expect(Defaults[.polishAndReplaceAdditionalPrompt] == "Polish with a formal tone")
    }

    @Test("Filters configured identifiers to eligible remote OpenAI-compatible services")
    func filtersConfiguredIdentifiers() {
        let customIdentifier = "\(ServiceType.customOpenAI.rawValue)#replacement-test-instance"
        let configuredIdentifiers = [
            ServiceType.gemini.rawValue,
            ServiceType.claude.rawValue,
            ServiceType.ollama.rawValue,
            ServiceType.claudeCode.rawValue,
            ServiceType.codexCLI.rawValue,
            ServiceType.google.rawValue,
            ServiceType.deepL.rawValue,
            ServiceType.doubao.rawValue,
            ServiceType.polishing.rawValue,
            ServiceType.openAI.rawValue,
            ServiceType.customOpenAI.rawValue,
            customIdentifier,
            ServiceType.deepSeek.rawValue,
            ServiceType.groq.rawValue,
            ServiceType.zhipu.rawValue,
            ServiceType.miniMax.rawValue,
            ServiceType.gitHub.rawValue,
            ServiceType.openAI.rawValue,
        ]
        let factory = QueryServiceFactory.shared

        let translateIdentifiers = factory.textReplacementServiceIdentifiers(
            for: .translate,
            configuredIdentifiers: configuredIdentifiers
        )
        let polishIdentifiers = factory.textReplacementServiceIdentifiers(
            for: .polish,
            configuredIdentifiers: configuredIdentifiers
        )

        #expect(
            translateIdentifiers == [
                ServiceType.builtInAI.rawValue,
                ServiceType.openAI.rawValue,
                customIdentifier,
                ServiceType.deepSeek.rawValue,
                ServiceType.groq.rawValue,
                ServiceType.zhipu.rawValue,
                ServiceType.miniMax.rawValue,
                ServiceType.gitHub.rawValue,
            ]
        )
        #expect(
            polishIdentifiers == [
                ServiceType.polishing.rawValue,
                ServiceType.builtInAI.rawValue,
                ServiceType.openAI.rawValue,
                customIdentifier,
                ServiceType.deepSeek.rawValue,
                ServiceType.groq.rawValue,
                ServiceType.zhipu.rawValue,
                ServiceType.miniMax.rawValue,
                ServiceType.gitHub.rawValue,
            ]
        )
    }

    @Test("Preserves the complete Custom OpenAI instance identifier")
    func preservesCustomOpenAIInstanceIdentifier() throws {
        let uuid = "replacement-test-uuid"
        let identifier = "\(ServiceType.customOpenAI.rawValue)#\(uuid)"
        let factory = QueryServiceFactory.shared

        let metadata = try #require(factory.metadata(withTypeId: identifier))
        let service = try #require(factory.service(withTypeId: identifier) as? CustomOpenAIService)

        #expect(metadata.serviceType == .customOpenAI)
        #expect(metadata.uuid == uuid)
        #expect(metadata.allowsMultipleInstances)
        #expect(metadata.textReplacementActions == [.translate, .polish])
        #expect(service.uuid == uuid)
    }

    @Test("Resets a deleted service instance to each action default")
    func resetsDeletedServiceInstanceToActionDefault() {
        let deletedIdentifier = "\(ServiceType.customOpenAI.rawValue)#deleted-instance"
        let factory = QueryServiceFactory.shared

        let translateResolution = factory.textReplacementServiceSelection(
            for: .translate,
            selectedIdentifier: deletedIdentifier,
            configuredIdentifiers: [ServiceType.openAI.rawValue]
        )
        let polishResolution = factory.textReplacementServiceSelection(
            for: .polish,
            selectedIdentifier: deletedIdentifier,
            configuredIdentifiers: [ServiceType.openAI.rawValue]
        )

        #expect(
            translateResolution == .init(
                identifier: ServiceType.builtInAI.rawValue,
                shouldResetStoredSelection: true
            )
        )
        #expect(
            polishResolution == .init(
                identifier: ServiceType.polishing.rawValue,
                shouldResetStoredSelection: true
            )
        )
    }

    @Test("Does not request reset for a configured selection")
    func doesNotResetConfiguredSelection() {
        let configuredIdentifier = "\(ServiceType.customOpenAI.rawValue)#configured-instance"

        let resolution = QueryServiceFactory.shared.textReplacementServiceSelection(
            for: .translate,
            selectedIdentifier: configuredIdentifier,
            configuredIdentifiers: [configuredIdentifier]
        )

        #expect(
            resolution == .init(
                identifier: configuredIdentifier,
                shouldResetStoredSelection: false
            )
        )
    }

    @Test("Empty additional requirements keep the default action prompts")
    func emptyAdditionalRequirementsKeepDefaultPrompts() {
        let service = isolatedCustomOpenAIService()
        let query = sampleQuery()

        service.textReplacementPromptContext = .init(
            action: .translate,
            additionalPrompt: "  \n"
        )
        let translationMessages = service.chatMessageDicts(query)

        service.textReplacementPromptContext = .init(
            action: .polish,
            additionalPrompt: "\t"
        )
        let polishingMessages = service.chatMessageDicts(query)

        #expect(messageRoles(translationMessages) == messageRoles(service.translationMessages(query)))
        #expect(messageContents(translationMessages) == messageContents(service.translationMessages(query)))
        #expect(messageRoles(polishingMessages) == messageRoles(service.polishingMessages(query)))
        #expect(messageContents(polishingMessages) == messageContents(service.polishingMessages(query)))
    }

    @Test("Non-empty additional requirements append without replacing the default prompt")
    func additionalRequirementsAppendToDefaultPrompt() throws {
        let service = isolatedCustomOpenAIService()
        let query = sampleQuery()
        let baseline = service.translationMessages(query)
        service.textReplacementPromptContext = .init(
            action: .translate,
            additionalPrompt: "  Prefer concise product terminology.  "
        )

        let messages = service.chatMessageDicts(query)
        let appendedMessage = try #require(messages.last)

        #expect(messageRoles(Array(messages.dropLast())) == messageRoles(baseline))
        #expect(messageContents(Array(messages.dropLast())) == messageContents(baseline))
        #expect(appendedMessage.role == .user)
        #expect(appendedMessage.content.contains("Prefer concise product terminology."))
        #expect(appendedMessage.content.contains("Additional requirements"))
    }

    @Test("Replacement prompts take precedence over a service global custom prompt")
    func replacementPromptsTakePrecedenceOverGlobalCustomPrompt() {
        let service = isolatedCustomOpenAIService()
        defer {
            Defaults.reset(service.enableCustomPromptKey)
            Defaults.reset(service.systemPromptKey)
            Defaults.reset(service.userPromptKey)
        }
        service.enableCustomPrompt = true
        service.systemPrompt = "GLOBAL_SYSTEM_PROMPT_MUST_NOT_APPEAR"
        service.userPrompt = "GLOBAL_USER_PROMPT_MUST_NOT_APPEAR"
        service.textReplacementPromptContext = .init(
            action: .translate,
            additionalPrompt: "Keep the product name unchanged."
        )

        let messages = service.chatMessageDicts(sampleQuery())
        let contents = messageContents(messages)

        #expect(contents.contains(where: { $0.contains("Selected source text") }))
        #expect(contents.contains(where: { $0.contains("Keep the product name unchanged.") }))
        #expect(!contents.contains(where: { $0.contains("GLOBAL_SYSTEM_PROMPT_MUST_NOT_APPEAR") }))
        #expect(!contents.contains(where: { $0.contains("GLOBAL_USER_PROMPT_MUST_NOT_APPEAR") }))
    }

    // MARK: Private

    private func isolatedCustomOpenAIService() -> CustomOpenAIService {
        let service = CustomOpenAIService()
        service.uuid = "text-replacement-tests-\(UUID().uuidString)"
        return service
    }

    private func sampleQuery() -> ChatQueryParam {
        .init(
            text: "Selected source text",
            sourceLanguage: .english,
            targetLanguage: .simplifiedChinese,
            queryType: .translation,
            enableSystemPrompt: true
        )
    }

    private func messageRoles(_ messages: [ChatMessage]) -> [ChatMessage.ChatRole] {
        messages.map(\.role)
    }

    private func messageContents(_ messages: [ChatMessage]) -> [String] {
        messages.map(\.content)
    }
}
