//
//  AppShortcutModifier.swift
//  Easydict
//
//  Created by tisfeng on 2025/8/25.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation
import Magnet
import SwiftUI

// MARK: - ShortcutModifier

struct ShortcutModifier: ViewModifier {
    let action: ShortcutAction

    func body(content: Content) -> some View {
        if let defaultsKey = action.defaultsKey {
            ShortcutModifierWithKey(content: content, defaultsKey: defaultsKey)
        } else {
            content
        }
    }
}

// MARK: - ShortcutModifierWithKey

struct ShortcutModifierWithKey<Content: View>: View {
    // MARK: Lifecycle

    init(content: Content, defaultsKey: Defaults.Key<KeyCombo?>) {
        self.content = content
        _shortcutKey = .init(defaultsKey)
    }

    // MARK: Internal

    let content: Content
    @Default var shortcutKey: KeyCombo?

    var body: some View {
        if let shortcutKey {
            content
                .keyboardShortcut(
                    fetchShortcutKeyEquivalent(shortcutKey),
                    modifiers: fetchShortcutKeyEventModifiers(shortcutKey)
                )
        } else {
            content
        }
    }

    // MARK: Private

    private func fetchShortcutKeyEquivalent(_ keyCombo: KeyCombo) -> KeyEquivalent {
        if keyCombo.doubledModifiers {
            KeyEquivalent(Character(keyCombo.keyEquivalentModifierMaskString))
        } else {
            KeyEquivalent(Character(keyCombo.keyEquivalent))
        }
    }

    private func fetchShortcutKeyEventModifiers(_ keyCombo: KeyCombo) -> SwiftUI.EventModifiers {
        let modifierMappings: [(NSEvent.ModifierFlags, SwiftUI.EventModifiers)] = [
            (.command, .command),
            (.control, .control),
            (.option, .option),
            (.shift, .shift),
        ]

        return modifierMappings.reduce(into: SwiftUI.EventModifiers()) { result, mapping in
            if keyCombo.keyEquivalentModifierMask.contains(mapping.0) {
                result.update(with: mapping.1)
            }
        }
    }
}

/// can't using keyEquivalent and EventModifiers in SwiftUI MenuItemView direct, because item
/// keyboardShortcut not support double modifier key but can use ⌥ as character
extension View {
    @ViewBuilder
    public func keyboardShortcut(_ action: ShortcutAction) -> some View {
        modifier(ShortcutModifier(action: action))
    }
}
