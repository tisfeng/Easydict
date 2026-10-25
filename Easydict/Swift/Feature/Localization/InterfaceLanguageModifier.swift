//
//  InterfaceLanguageModifier.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import Combine
import SwiftUI

/// Gives every SwiftUI window the selected app locale and live layout direction.
private struct InterfaceLanguageModifier: ViewModifier {
    var onChange: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .environment(\.locale, Locale(identifier: language.rawValue))
            .environment(\.layoutDirection, language.layoutDirection)
            .onAppear {
                onChange?()
            }
            .onReceive(
                NotificationCenter.default.publisher(for: .languagePreferenceChanged)
                    .receive(on: RunLoop.main)
            ) { _ in
                onChange?()
            }
    }

    @AppStorage(languagePreferenceLocalKey)
    private var language: LanguageState.LanguageType = I18nHelper.shared.languageType
}

extension View {
    /// Also refreshes an AppKit window's localized title when supplied by its owner.
    func interfaceLanguage(onChange: (() -> Void)? = nil) -> some View {
        modifier(InterfaceLanguageModifier(onChange: onChange))
    }
}
