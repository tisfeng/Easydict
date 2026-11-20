//
//  CodexServiceConfig.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Combine
import Defaults
import Foundation

// MARK: - CodexServiceConfig

/// Captures mode and model settings without invoking StreamService's model getter.
/// Fixed storage keys keep managed settings separate from the external CLI values.
struct CodexServiceConfig: Equatable {
    // MARK: Lifecycle

    init(uuid: String) {
        self.uuid = uuid
        self.mode = Defaults[CodexAccessMode.key(uuid: uuid)]
        self.model = Defaults[Self.modelKey(uuid: uuid, mode: mode)]
        self.effort = Defaults[Self.effortKey(uuid: uuid, mode: mode)]
        self.fastMode = mode == .managed && Defaults[Self.fastModeKey(uuid: uuid)]
        self.isCustomModel = mode == .managed
            && !CodexRuntime.bundledModelNames.contains(model)
            && Defaults[Self.customModelsKey(uuid: uuid)].contains(model)
    }

    // MARK: Internal

    let uuid: String
    let mode: CodexAccessMode
    let model: String
    let effort: CodexReasoningEffort

    let isCustomModel: Bool
    let fastMode: Bool

    var connection: CodexAppServerRequest.Connection {
        if mode == .localCLI { return .localCLI }
        return isCustomModel ? .custom : .managed()
    }

    static func fastModeKey(uuid: String) -> Defaults.Key<Bool> {
        serivceConfigurationKey(.codexManagedFastMode, serviceType: .codexCLI, id: uuid, defaultValue: false)
    }

    static func customModelsKey(uuid: String) -> Defaults.Key<[String]> {
        serivceConfigurationKey(.codexManagedCustomModels, serviceType: .codexCLI, id: uuid, defaultValue: [])
    }

    static func hiddenModelsKey(uuid: String) -> Defaults.Key<[String]> {
        serivceConfigurationKey(.codexManagedHiddenModels, serviceType: .codexCLI, id: uuid, defaultValue: [])
    }

    static func lastVerifiedKey(uuid: String) -> Defaults.Key<[String: String]> {
        serivceConfigurationKey(
            .codexManagedLastVerifiedSelection, serviceType: .codexCLI, id: uuid, defaultValue: [:]
        )
    }

    static func models(uuid: String) -> [String] {
        models(customModels: Defaults[customModelsKey(uuid: uuid)], hiddenModels: Defaults[hiddenModelsKey(uuid: uuid)])
    }

    static func models(customModels: [String], hiddenModels: [String]) -> [String] {
        var models = CodexRuntime.bundledModelNames
        for model in customModels where CodexModelCatalog.isValidModelID(model) && !models.contains(model) {
            models.append(model)
        }
        let hidden = Set(hiddenModels)
        return models.filter { !hidden.contains($0) }
    }

    static func reasoningEfforts(
        mode: CodexAccessMode, model: String,
        localModels: [CodexAppServer.LocalModel] = []
    )
        -> [CodexReasoningEffort] {
        switch mode {
        case .localCLI:
            [.default] + (localModel(model, in: localModels)?.efforts.filter { $0 != .default } ?? [])
        case .managed:
            if let entry = CodexRuntime.bundledCatalog?.models.first(where: { $0.slug == model }) {
                [.default] + entry.supported_reasoning_levels.compactMap { CodexReasoningEffort(rawValue: $0.effort) }
            } else {
                CodexReasoningEffort.customOptions
            }
        }
    }

    static func localModel(_ model: String, in models: [CodexAppServer.LocalModel])
        -> CodexAppServer.LocalModel? {
        let model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        return models.first { model.isEmpty ? $0.isDefault : $0.identifier == model }
    }

    /// Repairs only selections disproven by a successfully discovered model.
    static func compatibleLocalEffort(
        _ effort: CodexReasoningEffort, model: String, models: [CodexAppServer.LocalModel]
    )
        -> CodexReasoningEffort {
        guard let selected = localModel(model, in: models), effort != .default,
              !selected.efforts.contains(effort) else { return effort }
        return effort == .minimal && selected.efforts.contains(.low) ? .low : .default
    }

    static func modelKey(uuid: String, mode: CodexAccessMode) -> Defaults.Key<String> {
        serivceConfigurationKey(
            mode == .managed ? .codexManagedModel : .model,
            serviceType: .codexCLI,
            id: uuid,
            defaultValue: mode == .managed ? CodexRuntime.defaultModel : ""
        )
    }

    static func effortKey(uuid: String, mode: CodexAccessMode) -> Defaults.Key<CodexReasoningEffort> {
        serivceConfigurationKey(
            mode == .managed ? .codexManagedReasoningEffort : .reasoningEffort,
            serviceType: .codexCLI,
            id: uuid,
            defaultValue: .default
        )
    }

    /// Called after a translation confirms the candidate for this service.
    func saveVerifiedModel(_ model: String) {
        let key = Self.customModelsKey(uuid: uuid)
        if !CodexRuntime.bundledModelNames.contains(model), !Defaults[key].contains(model) {
            Defaults[key].append(model)
        }
        Defaults[Self.hiddenModelsKey(uuid: uuid)].removeAll { $0 == model }
    }

    /// Removes a visible entry without changing an unrelated selection or the runtime catalog.
    func removeModel(_ removedModel: String) {
        let visible = Self.models(uuid: uuid)
        guard mode == .managed, self == Self(uuid: uuid), visible.contains(removedModel) else { return }
        let verified = Defaults[Self.lastVerifiedKey(uuid: uuid)]
        if model == removedModel {
            let remaining = visible.filter { $0 != removedModel }
            let previous = verified["model"].flatMap { remaining.contains($0) ? $0 : nil }
            let fallback = previous ?? (remaining.contains(CodexRuntime.defaultModel)
                ? CodexRuntime.defaultModel : remaining.first ?? "")
            let effort = previous == nil ? CodexReasoningEffort.default
                : verified["effort"].flatMap(CodexReasoningEffort.init(rawValue:)) ?? .default
            Defaults[Self.modelKey(uuid: uuid, mode: .managed)] = fallback
            Defaults[Self.effortKey(uuid: uuid, mode: .managed)] = Self.reasoningEfforts(
                mode: .managed,
                model: fallback
            )
            .contains(effort) ? effort : .default
        }
        if CodexRuntime.bundledModelNames.contains(removedModel) {
            let key = Self.hiddenModelsKey(uuid: uuid)
            if !Defaults[key].contains(removedModel) { Defaults[key].append(removedModel) }
        } else {
            Defaults[Self.customModelsKey(uuid: uuid)].removeAll { $0 == removedModel }
        }
        if verified["model"] == removedModel { Defaults[Self.lastVerifiedKey(uuid: uuid)] = [:] }
    }

    /// A recovery preference records success, not a permanent account entitlement.
    func rememberSuccessfulSelection() {
        guard mode == .managed, self == Self(uuid: uuid) else { return }
        Defaults[Self.lastVerifiedKey(uuid: uuid)] = ["model": model, "effort": effort.rawValue]
    }
}
