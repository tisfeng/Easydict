//
//  CodexServiceConfiguration.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Combine
import Defaults
import Foundation

// MARK: - CodexServiceConfiguration

/// Captures mode and model settings without invoking StreamService's model getter.
/// Fixed storage keys keep managed settings separate from the external CLI values.
struct CodexServiceConfiguration: Equatable {
    // MARK: Lifecycle

    init(uuid: String) {
        self.uuid = uuid
        self.mode = Defaults[CodexAccessMode.key(uuid: uuid)]
        self.model = Defaults[Self.modelKey(uuid: uuid, mode: mode)]
        self.effort = Defaults[Self.effortKey(uuid: uuid, mode: mode)]
    }

    // MARK: Internal

    let uuid: String
    let mode: CodexAccessMode
    let model: String
    let effort: CodexReasoningEffort

    static func reasoningEfforts(
        mode: CodexAccessMode, model: String,
        localModels: [CodexAppServer.LocalModel] = []
    )
        -> [CodexReasoningEffort] {
        switch mode {
        case .localCLI:
            [.default] + (localModel(model, in: localModels)?.efforts.filter { $0 != .default } ?? [])
        case .managed:
            [.default] + (CodexManagedRuntime.bundledCatalog?.models.first { $0.slug == model }?
                .supported_reasoning_levels.compactMap { CodexReasoningEffort(rawValue: $0.effort) } ?? [])
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
            defaultValue: mode == .managed ? CodexManagedRuntime.defaultModel : ""
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
}
