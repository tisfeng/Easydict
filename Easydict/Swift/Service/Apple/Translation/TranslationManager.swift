//
//  TranslationManager.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/10.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import Translation

// MARK: - TranslationManager

@available(macOS 15.0, *)
class TranslationManager: ObservableObject {
    // MARK: Internal

    @Published var sourceText: String = ""
    @Published var targetText: String = ""
    @Published var configuration: TranslationSession.Configuration?

    @MainActor
    func translate(
        text: String,
        sourceLanguage: Locale.Language?,
        targetLanguage: Locale.Language?
    ) async throws
        -> TranslationSession.Response {
        sourceText = text

        return try await withCheckedThrowingContinuation { continuation in
            translationContinuation = continuation

            if configuration == nil {
                configuration = .init(source: sourceLanguage, target: targetLanguage)
                return
            }

            configuration?.source = sourceLanguage
            configuration?.target = targetLanguage
            configuration?.invalidate()
        }
    }

    func performTranslation(_ session: TranslationSession) {
        Task {
            do {
                let response = try await session.translate(sourceText)
                await MainActor.run {
                    self.targetText = response.targetText
                }
                translationContinuation?.resume(returning: response)
            } catch {
                translationContinuation?.resume(throwing: error)
            }
            translationContinuation = nil
        }
    }

    func cancelTranslation() {
        configuration?.invalidate()
        configuration = nil
        translationContinuation?.resume(throwing: CancellationError())
        translationContinuation = nil
    }

    // MARK: Private

    private var translationContinuation: CheckedContinuation<TranslationSession.Response, Error>?
}
