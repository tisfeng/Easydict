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

public struct KeyHolderDataItem: Identifiable {
    public var id: String { type.localizedStringKey() }
    var type: ShortcutType
}

struct KeyHolderWrapper: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        .init(shortcutType: type, confictAlterMessage: $confictAlterMessage)
    }

    private var type: ShortcutType
    @Binding var confictAlterMessage: ShortcutConfictAlertMessage
    init(shortcutType: ShortcutType, confictAlterMessage: Binding<ShortcutConfictAlertMessage>) {
        type = shortcutType
        _confictAlterMessage = confictAlterMessage
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
}

extension KeyHolderWrapper {
    class Coordinator: NSObject, RecordViewDelegate {
        private var type: ShortcutType
        @Binding var confictAlterMessage: ShortcutConfictAlertMessage
        init(shortcutType: ShortcutType, confictAlterMessage: Binding<ShortcutConfictAlertMessage>) {
            type = shortcutType
            _confictAlterMessage = confictAlterMessage
        }

        func recordViewShouldBeginRecording(_: KeyHolder.RecordView) -> Bool {
            true
        }

        func recordView(_: KeyHolder.RecordView, canRecordKeyCombo _: Magnet.KeyCombo) -> Bool {
            true
        }

        func recordViewDidEndRecording(_: RecordView) {}

        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            if keyCombo == nil { // clear shortcut
                Shortcut.shared.updateMenu(type)
            }
            if let key = keyCombo {
                // shortcut validate confict
                if Shortcut.validateShortcut(key) {
                    if #available(macOS 12, *) {
                        confictAlterMessage = ShortcutConfictAlertMessage(title: String(localized: "shortcut_confict_title \(keyCombo!.keyEquivalentModifierMaskString + keyCombo!.characters)"), message: String(localized: "shortcut_confict_message \(Shortcut.shared.confictMenuItem?.title ?? "")"))
                    } else {
                        // Fallback on earlier versions
                        let title = NSLocalizedString("shortcut_confict_title \(keyCombo!.keyEquivalentModifierMaskString + keyCombo!.characters)", comment: "")
                        let msg = NSLocalizedString("shortcut_confict_message \(Shortcut.shared.confictMenuItem?.title ?? "")", comment: "")
                        confictAlterMessage = ShortcutConfictAlertMessage(title: title, message: msg)
                    }
                    recordView.clear()
                    return
                }
            }
            storeKeyCombo(with: keyCombo)
            Shortcut.shared.bindingShortcut(keyCombo: keyCombo, type: type)
        }

        func restoreKeyCombo(_ recordView: RecordView) {
            var keyCombo: KeyCombo?
            switch type {
            case .inputTranslate:
                keyCombo = Defaults[.inputShortcut]
            case .snipTranslate:
                keyCombo = Defaults[.snipShortcut]
            case .selectTranslate:
                keyCombo = Defaults[.selectionShortcut]
            case .silentScreenshotOcr:
                keyCombo = Defaults[.screenshotOCRShortcut]
            case .showMiniWindow:
                keyCombo = Defaults[.showMiniWindowShortcut]
            case .clearInput:
                keyCombo = Defaults[.clearInputShortcut]
            case .clearAll:
                keyCombo = Defaults[.clearAllShortcut]
            case .copy:
                keyCombo = Defaults[.copyShortcut]
            case .copyFirstResult:
                keyCombo = Defaults[.copyFirstResultShortcut]
            case .focus:
                keyCombo = Defaults[.focusShortcut]
            case .play:
                keyCombo = Defaults[.playShortcut]
            case .retry:
                keyCombo = Defaults[.retryShortcut]
            case .toggle:
                keyCombo = Defaults[.toggleShortcut]
            case .pin:
                keyCombo = Defaults[.pinShortcut]
            case .hide:
                keyCombo = Defaults[.hideShortcut]
            case .increaseFontSize:
                keyCombo = Defaults[.increaseFontSize]
            case .decreaseFontSize:
                keyCombo = Defaults[.decreaseFontSize]
            case .google:
                keyCombo = Defaults[.googleShortcut]
            case .eudic:
                keyCombo = Defaults[.eudicShortcut]
            case .appleDic:
                keyCombo = Defaults[.appleDictionaryShortcut]
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
    }
}
