//
//  TranslationExample.swift
//  AppleTranslation
//
//  Created by tisfeng on 2024/10/10.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI
import Translation

// MARK: - TranslationView

@available(macOS 15.0, *)
struct TranslationView: View {
    @ObservedObject var manager: TranslationManager

    var body: some View {
        VStack {
            TextField("", text: $manager.sourceText)
            Text(manager.targetText)
        }
        .padding()
        .translationTask(manager.configuration) { session in
            manager.performTranslation(session)
        }
    }
}
