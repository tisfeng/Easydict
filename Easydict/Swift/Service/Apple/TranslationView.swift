//
//  TranslationExample.swift
//  Easydict
//
//  Created by tisfeng on 2024/10/10.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI
import Translation

// MARK: - TranslationView

@available(macOS 15.0, *)
struct TranslationView: View {
    // MARK: Internal

    @State private var sourceText: String = "good"
    @State private var targetText: String = ""

    @State private var configuration: TranslationSession.Configuration?

    var sourceLanguage: Locale.Language?
    var targetLanguage: Locale.Language?

    var body: some View {
        HStack {
            TextField("", text: $sourceText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    triggerTranslation()
                }

            TextField("", text: $targetText)
                .textFieldStyle(.roundedBorder)
                .disabled(true)
        }
        .translationTask(configuration) { session in
            do {
                logInfo("translate")

                let response = try await session.translate(sourceText)
                targetText = response.targetText

                logInfo("targetText: \(targetText)")
            } catch {
                logError("translate error: \(error)")
            }
        }
        .onAppear {
            triggerTranslation()
        }
        .padding()
    }

    // MARK: Private

    private func triggerTranslation() {
        guard configuration == nil else {
            configuration?.invalidate()
            return
        }

        configuration = .init(source: sourceLanguage, target: targetLanguage)
    }
}

@available(macOS 15.0, *)
#Preview {
//    return TranslationView()
    Text("about")
}
