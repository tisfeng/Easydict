//
//  KeyHolderWrapper.swift
//  Easydict
//
//  Created by Sharker on 2024/1/2.
//  Copyright © 2024 izual. All rights reserved.
//

import AppKit
import Defaults
import KeyHolder
import Magnet
import SwiftUI

// MARK: - KeyHolderWrapper

struct KeyHolderWrapper: NSViewRepresentable {
    // MARK: Lifecycle

    init(shortcutType: ShortcutAction, confictAlterMessage: Binding<ShortcutConfictAlertMessage>) {
        self.type = shortcutType
        _confictAlterMessage = confictAlterMessage
    }

    // MARK: Internal

    @Binding var confictAlterMessage: ShortcutConfictAlertMessage

    func makeCoordinator() -> Coordinator {
        .init(shortcutType: type, confictAlterMessage: $confictAlterMessage)
    }

    func makeNSView(context: Context) -> some NSView {
        let recordView = RecordView(frame: CGRect.zero)
        recordView.tintColor = NSColor(red: 0.164, green: 0.517, blue: 0.823, alpha: 1)
        recordView.delegate = context.coordinator
        recordView.layer?.cornerRadius = 6.0
        recordView.layer?.masksToBounds = true
        recordView.clearButtonMode = .whenRecorded

        context.coordinator.restoreKeyCombo(recordView)
        return recordView
    }

    func updateNSView(_: NSViewType, context _: Context) {}

    // MARK: Private

    private var type: ShortcutAction
}

// MARK: KeyHolderWrapper.Coordinator

extension KeyHolderWrapper {
    class Coordinator: NSObject, RecordViewDelegate {
        // MARK: Lifecycle

        init(
            shortcutType: ShortcutAction, confictAlterMessage: Binding<ShortcutConfictAlertMessage>
        ) {
            self.action = shortcutType
            _confictAlterMessage = confictAlterMessage
        }

        // MARK: Internal

        @Binding var confictAlterMessage: ShortcutConfictAlertMessage

        func recordViewShouldBeginRecording(_: KeyHolder.RecordView) -> Bool {
            Configuration.shared.isRecordingSelectTextShortcutKey = true
            return true
        }

        func recordView(_: KeyHolder.RecordView, canRecordKeyCombo _: Magnet.KeyCombo) -> Bool {
            true
        }

        func recordViewDidEndRecording(_: RecordView) {
            Configuration.shared.isRecordingSelectTextShortcutKey = false
        }

        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            if let key = keyCombo {
                // shortcut validate confict
                if ShortcutManager.validateShortcut(key) {
                    let title =
                        String(
                            localized:
                            "shortcut_confict_title \(key.keyEquivalentModifierMaskString + key.characters)"
                        )
                    let message =
                        String(
                            localized:
                            "shortcut_confict_message \(ShortcutManager.shared.confictMenuItem?.title ?? "")"
                        )
                    confictAlterMessage = ShortcutConfictAlertMessage(
                        title: title,
                        message: message
                    )
                    recordView.clear()
                    HotKeyCenter.shared.unregisterHotKey(with: action.rawValue)
                    return
                }
            } else {
                // clear shortcut
                ShortcutManager.shared.updateMenu(action)
            }
            storeKeyCombo(with: keyCombo)
            ShortcutManager.shared.bindingShortcutAction(keyCombo: keyCombo, action: action)
        }

        /// Restore the key combo for the given record view based on the shortcut type.
        func restoreKeyCombo(_ recordView: RecordView) {
            let keyCombo = getKeyCombo()
            recordView.keyCombo = keyCombo
            ShortcutManager.shared.bindingShortcutAction(keyCombo: keyCombo, action: action)
        }

        /// Store the key combo for the shortcut type.
        func storeKeyCombo(with keyCombo: KeyCombo?) {
            setKeyCombo(keyCombo)
        }

        // MARK: Private

        private var action: ShortcutAction

        /// Mapping from ShortcutType to corresponding Defaults.Key
        private var shortcutTypeToDefaultsKey: [ShortcutAction: DefaultsKeyWrapper] {
            [
                .inputTranslate: DefaultsKeyWrapper(.inputShortcut),
                .snipTranslate: DefaultsKeyWrapper(.snipShortcut),
                .selectTranslate: DefaultsKeyWrapper(.selectionShortcut),
                .silentScreenshotOCR: DefaultsKeyWrapper(.silentScreenshotOCRShortcut),
                .showMiniWindow: DefaultsKeyWrapper(.showMiniWindowShortcut),
                .pasteboardTranslate: DefaultsKeyWrapper(.pasteboardTranslateShortcut),
                .translateAndReplace: DefaultsKeyWrapper(.translateAndReplaceShortcut),
                .polishAndReplace: DefaultsKeyWrapper(.polishAndReplaceShortcut),
                .clearInput: DefaultsKeyWrapper(.clearInputShortcut),
                .clearAll: DefaultsKeyWrapper(.clearAllShortcut),
                .copy: DefaultsKeyWrapper(.copyShortcut),
                .copyFirstResult: DefaultsKeyWrapper(.copyFirstResultShortcut),
                .focus: DefaultsKeyWrapper(.focusShortcut),
                .play: DefaultsKeyWrapper(.playShortcut),
                .retry: DefaultsKeyWrapper(.retryShortcut),
                .toggle: DefaultsKeyWrapper(.toggleShortcut),
                .pin: DefaultsKeyWrapper(.pinShortcut),
                .hide: DefaultsKeyWrapper(.hideShortcut),
                .increaseFontSize: DefaultsKeyWrapper(.increaseFontSize),
                .decreaseFontSize: DefaultsKeyWrapper(.decreaseFontSize),
                .google: DefaultsKeyWrapper(.googleShortcut),
                .eudic: DefaultsKeyWrapper(.eudicShortcut),
                .appleDic: DefaultsKeyWrapper(.appleDictionaryShortcut),
            ]
        }

        // MARK: - Private Helper Methods

        /// Get the current key combo for the shortcut type.
        private func getKeyCombo() -> KeyCombo? {
            guard let defaultsKey = shortcutTypeToDefaultsKey[action] else { return nil }
            return defaultsKey.getValue()
        }

        /// Set the key combo for the shortcut type.
        private func setKeyCombo(_ keyCombo: KeyCombo?) {
            guard let defaultsKey = shortcutTypeToDefaultsKey[action] else { return }
            defaultsKey.setValue(keyCombo)
        }
    }
}

// MARK: - DefaultsKeyWrapper

/// A wrapper to handle type-erased access to Defaults.Key<KeyCombo?>
private struct DefaultsKeyWrapper {
    // MARK: Lifecycle

    init(_ key: Defaults.Key<KeyCombo?>) {
        self.getter = { Defaults[key] }
        self.setter = { Defaults[key] = $0 }
    }

    // MARK: Internal

    func getValue() -> KeyCombo? {
        getter()
    }

    func setValue(_ value: KeyCombo?) {
        setter(value)
    }

    // MARK: Private

    private let getter: () -> KeyCombo?
    private let setter: (KeyCombo?) -> ()
}
