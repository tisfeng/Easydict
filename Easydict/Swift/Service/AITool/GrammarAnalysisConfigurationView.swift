//
//  GrammarAnalysisConfigurationView.swift
//  Easydict
//
//  Created by Yi Miao on 2026/7/6.
//

import Defaults
import SwiftUI

// MARK: - GrammarAnalysisMode

/// Defines whether grammar analysis follows a general tutoring style or an
/// IELTS-focused coaching style.
enum GrammarAnalysisMode: String, CaseIterable, Defaults.Serializable, EnumLocalizedStringConvertible {
    case general
    case ielts

    // MARK: Internal

    var promptLabel: String {
        switch self {
        case .general:
            "general grammar analysis"
        case .ielts:
            "IELTS grammar analysis"
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .general:
            "grammar.analysis.mode.general.title"
        case .ielts:
            "grammar.analysis.mode.ielts.title"
        }
    }
}

// MARK: - GrammarAnalysisCredentialSource

/// Selects whether grammar analysis uses the built-in shared credential or a
/// user-provided provider key.
enum GrammarAnalysisCredentialSource: String, CaseIterable, Defaults.Serializable, EnumLocalizedStringConvertible {
    case builtIn
    case userKey
    case deepSeekKey

    // MARK: Internal

    var title: LocalizedStringKey {
        switch self {
        case .builtIn:
            "grammar.analysis.credential_source.built_in.title"
        case .userKey:
            "grammar.analysis.credential_source.openai_key.title"
        case .deepSeekKey:
            "grammar.analysis.credential_source.deepseek_key.title"
        }
    }

    var usesPrivateKey: Bool {
        self != .builtIn
    }
}

// MARK: - GrammarAnalysisProvider

/// Chooses which OpenAI-compatible provider preset the user-managed credential
/// should start from.
enum GrammarAnalysisProvider: String, CaseIterable, Defaults.Serializable, EnumLocalizedStringConvertible {
    case openAI = "openai"
    case deepSeek = "deepseek"
    case customOpenAICompatible = "custom_openai_compatible"

    // MARK: Internal

    var title: LocalizedStringKey {
        switch self {
        case .openAI:
            "grammar.analysis.provider.openai.title"
        case .deepSeek:
            "grammar.analysis.provider.deepseek.title"
        case .customOpenAICompatible:
            "grammar.analysis.provider.custom_compatible.title"
        }
    }
}

// MARK: - GrammarAnalysisConfigurationView

/// Renders grammar-analysis-specific settings while reusing the shared stream
/// service configuration form for model and prompt-related controls.
struct GrammarAnalysisConfigurationView: View {
    // MARK: Lifecycle

    init(service: GrammarAnalysisService) {
        self.service = service
        service.normalizeAnalysisModeIfNeeded()
        _credentialSource = .init(service.credentialSourceKey)
    }

    // MARK: Internal

    var body: some View {
        Section {
            StaticPickerCell(
                titleKey: "grammar.analysis.mode.title",
                key: service.analysisModeKey,
                values: availableModes
            )

            StaticPickerCell(
                titleKey: "grammar.analysis.credential_source.title",
                key: service.credentialSourceKey,
                values: GrammarAnalysisCredentialSource.allCases
            )
        }

        StreamConfigurationView(
            service: service,
            showAPIKeySection: credentialSource.usesPrivateKey,
            showEndpointSection: credentialSource.usesPrivateKey,
            showSupportedModelsSection: credentialSource.usesPrivateKey,
            showUsedModelSection: true,
            showCustomPromptSection: false,
            showTranslationToggle: false,
            showSentenceToggle: false,
            showDictionaryToggle: false,
            showUsageStatusPicker: true
        )
        .id(streamConfigurationIdentity)
        .onChange(of: credentialSource) { _ in
            GlobalContext.shared.reloadLLMServicesSubscribers()
        }
    }

    // MARK: Private

    private let service: GrammarAnalysisService

    @Default private var credentialSource: GrammarAnalysisCredentialSource

    private var availableModes: [GrammarAnalysisMode] {
        service.canUseIELTSMode ? GrammarAnalysisMode.allCases : [.general]
    }

    private var streamConfigurationIdentity: String {
        "\(credentialSource.rawValue)-\(service.provider.rawValue)"
    }
}
