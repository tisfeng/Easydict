//
//  GeneralKeyHolderWrapper.swift
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

struct GeneralKeyHolderWrapper: NSViewRepresentable {
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

extension GeneralKeyHolderWrapper {
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
            if let key = keyCombo {
                // shortcut validate confict
                if Shortcut.validateShortcut(key) {
                    confictAlterMessage = ShortcutConfictAlertMessage(message: "shortcut_confict_message\(String(describing: Shortcut.shared.confictMenuItem?.title))")
                    recordView.clear()
                    return
                }
            }
            storeKeyCombo(with: keyCombo)
            Shortcut.shared.bindingShortCut(keyCombo: keyCombo, type: type)
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
            }
            recordView.keyCombo = keyCombo
            Shortcut.shared.bindingShortCut(keyCombo: keyCombo, type: type)
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
            }
        }
    }
}
