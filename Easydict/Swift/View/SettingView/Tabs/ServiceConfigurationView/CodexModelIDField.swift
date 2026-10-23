//
//  CodexModelIDField.swift
//  Easydict
//

import AppKit
import SwiftUI

/// Reports edits through one delegate without rewriting an unchanged field editor.
struct CodexModelIDField: NSViewRepresentable {
    final class Coordinator: NSObject, NSTextFieldDelegate {
        // MARK: Lifecycle

        init(parent: CodexModelIDField) { self.parent = parent }

        // MARK: Internal

        var parent: CodexModelIDField

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField, parent.text != field.stringValue else { return }
            parent.text = field.stringValue
        }

        @objc
        func submit(_ sender: NSTextField) {
            parent.onSubmit()
        }
    }

    @Binding var text: String

    let isEnabled: Bool
    let onSubmit: () -> ()

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.alignment = .center
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.isContinuous = false
        field.cell?.sendsActionOnEndEditing = false
        field.isAutomaticTextCompletionEnabled = false
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.submit(_:))
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        updateNSView(field, context: context)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.parent = self
        if field.stringValue != text { field.stringValue = text }
        field.isEnabled = isEnabled
        field.placeholderString = String(
            localized: "service.codex_cli.custom_models.placeholder", locale: context.environment.locale
        )
        field.setAccessibilityLabel(String(
            localized: "service.codex_cli.custom_models.model_id", locale: context.environment.locale
        ))
    }
}
