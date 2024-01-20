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

enum ShortcutType {
    case inputTranslate
    case snipTranslate
    case selectTranslate
    case silentScreenshotOcr
}

struct GeneralKeyHolderWrapper: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        .init(shortcutType: type)
    }

    private var type: ShortcutType
    init(shortcutType: ShortcutType) {
        type = shortcutType
    }

    func makeNSView(context: Context) -> some NSView {
        let recordView = RecordView(frame: CGRect.zero)
        recordView.tintColor = NSColor(red: 0.164, green: 0.517, blue: 0.823, alpha: 1)
        recordView.delegate = context.coordinator
        recordView.layer?.cornerRadius = 6.0
        recordView.layer?.masksToBounds = true
        recordView.clearButtonMode = .whenRecorded

        restoreKeyCombo(context, recordView)
        return recordView
    }

    func updateNSView(_: NSViewType, context _: Context) {}

    private func restoreKeyCombo(_ context: Context, _ recordView: RecordView) {
        var data: Data
        switch type {
        case .inputTranslate:
            data = Defaults[.inputShortcutKey]
        case .snipTranslate:
            data = Defaults[.snipShortcutKey]
        case .selectTranslate:
            data = Defaults[.selectionShortcutKey]
        case .silentScreenshotOcr:
            data = Defaults[.screenshotOCRShortcutKey]
        }
        guard let keyCombo = try? JSONDecoder().decode(KeyCombo.self, from: data) else { return }
        recordView.keyCombo = keyCombo
        let hotKey = HotKey(identifier: "KeyHolderExample",
                            keyCombo: keyCombo,
                            target: context.coordinator,
                            action: #selector(context.coordinator.hotkeyCalled))
        hotKey.register()
    }
}

extension GeneralKeyHolderWrapper {
    class Coordinator: NSObject, RecordViewDelegate {
        private var type: ShortcutType
        init(shortcutType: ShortcutType) {
            type = shortcutType
        }

        func recordViewShouldBeginRecording(_: KeyHolder.RecordView) -> Bool {
            true
        }

        func recordView(_: KeyHolder.RecordView, canRecordKeyCombo _: Magnet.KeyCombo) -> Bool {
            true
        }

        func recordViewDidEndRecording(_: RecordView) {}

        func recordView(_: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            storeKeyCombo(with: keyCombo)
            HotKeyCenter.shared.unregisterAll()
            guard let keyCombo else { return }
            let hotKey = HotKey(identifier: "KeyHolderExample",
                                keyCombo: keyCombo,
                                target: self,
                                action: #selector(hotkeyCalled))
            hotKey.register()
        }

        // shortcut
        func storeKeyCombo(with keyCombo: KeyCombo?) {
            let data = try? JSONEncoder().encode(keyCombo)
            switch type {
            case .inputTranslate:
                Defaults[.inputShortcutKey] = data ?? Data()
            case .snipTranslate:
                Defaults[.snipShortcutKey] = data ?? Data()
            case .selectTranslate:
                Defaults[.selectionShortcutKey] = data ?? Data()
            case .silentScreenshotOcr:
                Defaults[.screenshotOCRShortcutKey] = data ?? Data()
            }
        }

        @objc func hotkeyCalled() {
            print("HotKey called!!!!")
        }
    }
}
