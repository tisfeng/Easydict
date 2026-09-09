//
//  QueryServiceFactory.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/16.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - TextReplacementAction

/// Identifies a global action that transforms selected text and writes the response back.
///
/// The default service remains action-specific so existing installations keep the same
/// translation and polishing behavior without a migration.
enum TextReplacementAction: String, Hashable {
    case translate
    case polish

    // MARK: Internal

    var defaultServiceIdentifier: String {
        switch self {
        case .translate:
            ServiceType.builtInAI.rawValue
        case .polish:
            ServiceType.polishing.rawValue
        }
    }
}

// MARK: - QueryServiceMetadata

/// Describes a registered query service without constructing its runtime instance.
struct QueryServiceMetadata {
    let serviceType: ServiceType
    let uuid: String
    let title: String
    let apiKeyRequirement: ServiceAPIKeyRequirement
    let isStream: Bool
    let allowsMultipleInstances: Bool
    let textReplacementActions: Set<TextReplacementAction>
}

// MARK: - TextReplacementServiceOption

/// A configured online service instance displayed by the text replacement settings.
struct TextReplacementServiceOption: Identifiable {
    let identifier: String
    let serviceType: ServiceType
    let uuid: String
    let title: String
    let model: String

    var id: String {
        identifier
    }

    func displayName(missingModelText: String) -> String {
        var serviceTitle = title
        if serviceType == .customOpenAI, !uuid.isEmpty {
            serviceTitle += " (\(String(uuid.prefix(8))))"
        }
        let visibleModel = model.isEmpty ? missingModelText : model
        return "\(serviceTitle) — \(visibleModel)"
    }
}

// MARK: - TextReplacementServiceSelectionResolution

/// Resolves a persisted action selection without conflating deletion with transient failures.
struct TextReplacementServiceSelectionResolution: Equatable {
    let identifier: String
    let shouldResetStoredSelection: Bool
}

// MARK: - ServiceRegistration

private struct ServiceRegistration {
    // MARK: Lifecycle

    init(
        _ serviceType: ServiceType,
        _ serviceClass: QueryService.Type,
        _ titleKey: String,
        apiKeyRequirement: ServiceAPIKeyRequirement = .userProvided,
        textReplacementActions: Set<TextReplacementAction> = [],
        allowsMultipleInstances: Bool = false
    ) {
        self.serviceType = serviceType
        self.serviceClass = serviceClass
        self.titleKey = titleKey
        self.apiKeyRequirement = apiKeyRequirement
        self.textReplacementActions = textReplacementActions
        self.allowsMultipleInstances = allowsMultipleInstances
    }

    // MARK: Internal

    let serviceType: ServiceType
    let serviceClass: QueryService.Type
    let titleKey: String
    let apiKeyRequirement: ServiceAPIKeyRequirement
    let textReplacementActions: Set<TextReplacementAction>
    let allowsMultipleInstances: Bool
}

// MARK: - QueryServiceFactory

/// A registry that maps `ServiceType` identifiers to their corresponding `QueryService` subclasses.
///
/// This class mirrors the legacy Objective-C `EZServiceTypes` API and stays accessible from both Objective-C and Swift.
@objcMembers
final class QueryServiceFactory: NSObject {
    // MARK: Internal

    /// Shared singleton instance.
    static let shared = QueryServiceFactory()

    var allServiceTypes: [ServiceType] {
        serviceRegistrations.map(\.serviceType)
    }

    var allServiceTypeIDs: [String] {
        allServiceTypes.map(\.rawValue)
    }

    func service(withTypeId typeIdIfHave: String) -> QueryService? {
        let components = serviceIdentifierComponents(from: typeIdIfHave)

        guard let serviceClass = serviceClass(withTypeId: typeIdIfHave) else {
            return nil
        }

        let service = serviceClass.init()
        service.uuid = components.uuid
        return service
    }

    func services(fromTypes types: [String]) -> [QueryService] {
        types.compactMap { service(withTypeId: $0) }
    }

    func isStreamService(typeIdIfHave: String) -> Bool {
        guard let serviceClass = serviceClass(withTypeId: typeIdIfHave) else {
            return false
        }
        return serviceClass is StreamService.Type
    }

    func metadata(withTypeId typeIdIfHave: String) -> QueryServiceMetadata? {
        let components = serviceIdentifierComponents(from: typeIdIfHave)
        guard let registration = serviceRegistration(withTypeId: typeIdIfHave) else { return nil }

        return QueryServiceMetadata(
            serviceType: registration.serviceType,
            uuid: components.uuid,
            title: title(
                for: registration.serviceType,
                uuid: components.uuid,
                fallbackKey: registration.titleKey
            ),
            apiKeyRequirement: registration.apiKeyRequirement,
            isStream: registration.serviceClass is StreamService.Type,
            allowsMultipleInstances: registration.allowsMultipleInstances,
            textReplacementActions: registration.textReplacementActions
        )
    }

    /// Returns configured service identifiers eligible for the requested replacement action.
    ///
    /// Membership comes from the union of all three window configurations and intentionally
    /// ignores each window's enabled state because these actions are global.
    func textReplacementServiceIdentifiers(for action: TextReplacementAction) -> [String] {
        let storage = LocalStorage.shared()
        let configuredIdentifiers = [EZWindowType.main, .fixed, .mini]
            .flatMap { storage.allServiceTypes($0) }
        return textReplacementServiceIdentifiers(
            for: action,
            configuredIdentifiers: configuredIdentifiers
        )
    }

    /// Filters an explicit configured identifier list using registered replacement capabilities.
    func textReplacementServiceIdentifiers(
        for action: TextReplacementAction,
        configuredIdentifiers: [String]
    )
        -> [String] {
        var candidates = [action.defaultServiceIdentifier]
        if action == .polish {
            candidates.append(ServiceType.builtInAI.rawValue)
        }
        candidates.append(contentsOf: configuredIdentifiers)

        var seenIdentifiers = Set<String>()
        return candidates.filter { identifier in
            guard seenIdentifiers.insert(identifier).inserted,
                  let metadata = metadata(withTypeId: identifier),
                  metadata.textReplacementActions.contains(action)
            else {
                return false
            }

            // The unqualified CustomOpenAI registration is an add-service template,
            // not a configured instance with its own credential namespace.
            return !(metadata.allowsMultipleInstances && metadata.uuid.isEmpty)
        }
    }

    /// Resolves the selected identifier against the current union of configured services.
    func textReplacementServiceSelection(
        for action: TextReplacementAction,
        selectedIdentifier: String
    )
        -> TextReplacementServiceSelectionResolution {
        let storage = LocalStorage.shared()
        let configuredIdentifiers = [EZWindowType.main, .fixed, .mini]
            .flatMap { storage.allServiceTypes($0) }
        return textReplacementServiceSelection(
            for: action,
            selectedIdentifier: selectedIdentifier,
            configuredIdentifiers: configuredIdentifiers
        )
    }

    /// Pure selection resolution used to distinguish a deleted service from request failures.
    func textReplacementServiceSelection(
        for action: TextReplacementAction,
        selectedIdentifier: String,
        configuredIdentifiers: [String]
    )
        -> TextReplacementServiceSelectionResolution {
        let eligibleIdentifiers = textReplacementServiceIdentifiers(
            for: action,
            configuredIdentifiers: configuredIdentifiers
        )
        guard eligibleIdentifiers.contains(selectedIdentifier) else {
            return .init(
                identifier: action.defaultServiceIdentifier,
                shouldResetStoredSelection: true
            )
        }
        return .init(identifier: selectedIdentifier, shouldResetStoredSelection: false)
    }

    /// Builds picker options from the current service configuration.
    func textReplacementServiceOptions(
        for action: TextReplacementAction
    )
        -> [TextReplacementServiceOption] {
        textReplacementServiceIdentifiers(for: action).compactMap { identifier in
            guard let metadata = metadata(withTypeId: identifier),
                  let service = service(withTypeId: identifier) as? BaseOpenAIService
            else {
                return nil
            }
            return TextReplacementServiceOption(
                identifier: identifier,
                serviceType: metadata.serviceType,
                uuid: metadata.uuid,
                title: metadata.title,
                model: service.model
            )
        }
    }

    /// Checks that an identifier still belongs to a configured eligible service instance.
    func isTextReplacementServiceAvailable(
        _ identifier: String,
        for action: TextReplacementAction
    )
        -> Bool {
        textReplacementServiceIdentifiers(for: action).contains(identifier)
    }

    /// Resolves a configured OpenAI-compatible service for a replacement action.
    func textReplacementService(
        withIdentifier identifier: String,
        for action: TextReplacementAction
    )
        -> BaseOpenAIService? {
        guard isTextReplacementServiceAvailable(identifier, for: action) else {
            return nil
        }
        return service(withTypeId: identifier) as? BaseOpenAIService
    }

    // MARK: Private

    private let serviceRegistrations: [ServiceRegistration] = [
        .init(.appleDictionary, AppleDictionary.self, "apple_dictionary", apiKeyRequirement: .none),
        .init(.mDict, MDictService.self, "service.mdict.name", apiKeyRequirement: .none),
        .init(.youdao, YoudaoService.self, "youdao_dict", apiKeyRequirement: .none),
        .init(
            .openAI,
            OpenAIService.self,
            "openai_translate",
            textReplacementActions: [.translate, .polish]
        ),
        .init(
            .deepSeek,
            DeepSeekService.self,
            "deepseek_translate",
            textReplacementActions: [.translate, .polish]
        ),
        .init(
            .groq,
            GroqService.self,
            "groq_translate",
            textReplacementActions: [.translate, .polish]
        ),
        .init(
            .zhipu,
            ZhipuService.self,
            "zhipu_translate",
            textReplacementActions: [.translate, .polish]
        ),
        .init(
            .miniMax,
            MiniMaxService.self,
            "minimax_translate",
            textReplacementActions: [.translate, .polish]
        ),
        .init(
            .gitHub,
            GitHubService.self,
            "github_models",
            textReplacementActions: [.translate, .polish]
        ),
        .init(
            .builtInAI,
            BuiltInAIService.self,
            "built_in_ai",
            apiKeyRequirement: .builtIn,
            textReplacementActions: [.translate, .polish]
        ),
        .init(.claudeCode, ClaudeCodeService.self, "service.claude_code.name", apiKeyRequirement: .agentCLI),
        .init(.codexCLI, CodexCLIService.self, "service.codex_cli.name", apiKeyRequirement: .agentCLI),
        .init(.gemini, GeminiService.self, "gemini_translate"),
        .init(.claude, ClaudeService.self, "claude_translate"),
        .init(.ollama, OllamaService.self, "ollama_translate", apiKeyRequirement: .none),
        .init(
            .polishing,
            PolishingService.self,
            "polishing_service",
            apiKeyRequirement: .builtIn,
            textReplacementActions: [.polish]
        ),
        .init(.summary, SummaryService.self, "summary_service", apiKeyRequirement: .builtIn),
        .init(
            .customOpenAI,
            CustomOpenAIService.self,
            "custom_openai",
            textReplacementActions: [.translate, .polish],
            allowsMultipleInstances: true
        ),
        .init(.deepL, DeepLService.self, "deepL_translate", apiKeyRequirement: .none),
        .init(.google, GoogleService.self, "google_translate", apiKeyRequirement: .none),
        .init(.apple, AppleService.self, "apple_translate", apiKeyRequirement: .none),
        .init(.baidu, BaiduService.self, "baidu_translate"),
        .init(.bing, BingService.self, "bing_translate", apiKeyRequirement: .none),
        .init(.volcano, VolcanoService.self, "volcano_translate"),
        .init(.niuTrans, NiuTransService.self, "niuTrans_translate", apiKeyRequirement: .builtIn),
        .init(.caiyun, CaiyunService.self, "caiyun_translate", apiKeyRequirement: .builtIn),
        .init(.tencent, TencentService.self, "tencent_translate"),
        .init(.alibaba, AliService.self, "ali_translate"),
        .init(.doubao, DoubaoService.self, "doubao_translate"),
    ]

    private func serviceClass(withTypeId typeIdIfHave: String) -> QueryService.Type? {
        serviceRegistration(withTypeId: typeIdIfHave)?.serviceClass
    }

    private func serviceRegistration(withTypeId typeIdIfHave: String) -> ServiceRegistration? {
        let components = serviceIdentifierComponents(from: typeIdIfHave)
        return serviceRegistrations.first { $0.serviceType.rawValue == components.rawType }
    }

    private func serviceIdentifierComponents(from typeIdIfHave: String)
        -> (rawType: String, uuid: String) {
        let components = typeIdIfHave.split(
            separator: "#",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        let rawType = String(components.first ?? Substring(typeIdIfHave))
        let uuid = components.count > 1 ? String(components[1]) : ""
        return (rawType, uuid)
    }

    private func title(for serviceType: ServiceType, uuid: String, fallbackKey: String) -> String {
        if serviceType == .customOpenAI {
            let nameKey = serivceConfigurationKey(
                .name,
                serviceType: serviceType,
                id: uuid,
                defaultValue: ""
            )
            let customName = Defaults[nameKey]
            if !customName.isEmpty {
                return customName
            }
        }
        return NSLocalizedString(fallbackKey, comment: "")
    }
}
