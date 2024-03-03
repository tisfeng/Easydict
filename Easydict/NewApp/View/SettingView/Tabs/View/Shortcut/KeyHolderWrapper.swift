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

// MARK: - KeyHolderDataItem

public struct KeyHolderDataItem: Identifiable {
    // MARK: Public

    public var id: String { type.localizedStringKey() }

    // MARK: Internal

    var type: ShortcutType
}

// MARK: - KeyHolderWrapper

@available(macOS 13, *)
struct KeyHolderWrapper: NSViewRepresentable {
    // MARK: Lifecycle

    init(shortcutType: ShortcutType, confictAlterMessage: Binding<ShortcutConfictAlertMessage>) {
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

    private var type: ShortcutType
}

// MARK: KeyHolderWrapper.Coordinator

@available(macOS 13, *)
extension KeyHolderWrapper {
    class Coordinator: NSObject, RecordViewDelegate {
        // MARK: Lifecycle

        init(shortcutType: ShortcutType, confictAlterMessage: Binding<ShortcutConfictAlertMessage>) {
            self.type = shortcutType
            _confictAlterMessage = confictAlterMessage
        }

        // MARK: Internal

        @Binding var confictAlterMessage: ShortcutConfictAlertMessage

        func recordViewShouldBeginRecording(_: KeyHolder.RecordView) -> Bool {
            true
        }

        func recordView(_: KeyHolder.RecordView, canRecordKeyCombo _: Magnet.KeyCombo) -> Bool {
            true
        }

        func recordViewDidEndRecording(_: RecordView) {}

        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            if let key = keyCombo {
                // shortcut validate confict
                if Shortcut.validateShortcut(key) {
                    let title =
                        String(
                            localized: "shortcut_confict_title \(key.keyEquivalentModifierMaskString + key.characters)",
                            bundle: localizedBundle
                        )
                    let message =
                        String(
                            localized: "shortcut_confict_message \(Shortcut.shared.confictMenuItem?.title ?? "")",
                            bundle: localizedBundle
                        )
                    confictAlterMessage = ShortcutConfictAlertMessage(
                        title: title,
                        message: message
                    )
                    recordView.clear()
                    return
                }
            } else { // clear shortcut
                Shortcut.shared.updateMenu(type)
            }
            storeKeyCombo(with: keyCombo)
            Shortcut.shared.bindingShortcut(keyCombo: keyCombo, type: type)
        }

        func restoreKeyCombo(_ recordView: RecordView) {
            let keyCombo: KeyCombo? = switch type {
            case .inputTranslate:
                Defaults[.inputShortcut]
            case .snipTranslate:
                Defaults[.snipShortcut]
            case .selectTranslate:
                Defaults[.selectionShortcut]
            case .silentScreenshotOcr:
                Defaults[.screenshotOCRShortcut]
            case .showMiniWindow:
                Defaults[.showMiniWindowShortcut]
            case .clearInput:
                Defaults[.clearInputShortcut]
            case .clearAll:
                Defaults[.clearAllShortcut]
            case .copy:
                Defaults[.copyShortcut]
            case .copyFirstResult:
                Defaults[.copyFirstResultShortcut]
            case .focus:
                Defaults[.focusShortcut]
            case .play:
                Defaults[.playShortcut]
            case .retry:
                Defaults[.retryShortcut]
            case .toggle:
                Defaults[.toggleShortcut]
            case .pin:
                Defaults[.pinShortcut]
            case .hide:
                Defaults[.hideShortcut]
            case .increaseFontSize:
                Defaults[.increaseFontSize]
            case .decreaseFontSize:
                Defaults[.decreaseFontSize]
            case .google:
                Defaults[.googleShortcut]
            case .eudic:
                Defaults[.eudicShortcut]
            case .appleDic:
                Defaults[.appleDictionaryShortcut]
            }
            recordView.keyCombo = keyCombo
            Shortcut.shared.bindingShortcut(keyCombo: keyCombo, type: type)
        }

        // shortcut
        func storeKeyCombo(with keyCombo: KeyCombo?) {
            switch type {
            case .inputTranslate:
                Defaults[.inputShortcut] = keyCombo
            case .snipTranslate:
                Defaults[.snipShortcut] = keyCombo
            case .selectTranslate:
                Defaults[.selectionShortcut] = keyCombo
            case .silentScreenshotOcr:
                Defaults[.screenshotOCRShortcut] = keyCombo
            case .showMiniWindow:
                Defaults[.showMiniWindowShortcut] = keyCombo
            case .clearInput:
                Defaults[.clearInputShortcut] = keyCombo
            case .clearAll:
                Defaults[.clearAllShortcut] = keyCombo
            case .copy:
                Defaults[.copyShortcut] = keyCombo
            case .copyFirstResult:
                Defaults[.copyFirstResultShortcut] = keyCombo
            case .focus:
                Defaults[.focusShortcut] = keyCombo
            case .play:
                Defaults[.playShortcut] = keyCombo
            case .retry:
                Defaults[.retryShortcut] = keyCombo
            case .toggle:
                Defaults[.toggleShortcut] = keyCombo
            case .pin:
                Defaults[.pinShortcut] = keyCombo
            case .hide:
                Defaults[.hideShortcut] = keyCombo
            case .increaseFontSize:
                Defaults[.increaseFontSize] = keyCombo
            case .decreaseFontSize:
                Defaults[.decreaseFontSize] = keyCombo
            case .google:
                Defaults[.googleShortcut] = keyCombo
            case .eudic:
                Defaults[.eudicShortcut] = keyCombo
            case .appleDic:
                Defaults[.appleDictionaryShortcut] = keyCombo
            }
        }

        // MARK: Private

        private var type: ShortcutType
    }
}
