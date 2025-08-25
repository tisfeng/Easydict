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
    // MARK: Lifecycle

    init(action: ShortcutAction) {
        _shortcutKey = .init(action.defaultsKey)
    }

    // MARK: Internal

    @Default var shortcutKey: KeyCombo?

    func body(content: Content) -> some View {
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

    private func fetchShortcutKeyEventModifiers(_ keyCombo: KeyCombo) -> EventModifiers {
        var modifiers: EventModifiers = []

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.command) {
            modifiers.update(with: EventModifiers.command)
        }

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.control) {
            modifiers.update(with: EventModifiers.control)
        }

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.option) {
            modifiers.update(with: EventModifiers.option)
        }

        if keyCombo.keyEquivalentModifierMask.contains(NSEvent.ModifierFlags.shift) {
            modifiers.update(with: EventModifiers.shift)
        }

        return modifiers
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
