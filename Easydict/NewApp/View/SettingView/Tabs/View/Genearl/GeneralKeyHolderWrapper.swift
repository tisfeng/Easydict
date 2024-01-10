//
//  GeneralKeyHolderWrapper.swift
//  Easydict
//
//  Created by Sharker on 2024/1/2.
//  Copyright © 2024 izual. All rights reserved.
//

import AppKit
import KeyHolder
import Magnet
import SwiftUI

struct GeneralKeyHolderWrapper: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        .init()
    }
    
    func makeNSView(context: Context) -> some NSView {
        let recordView = RecordView(frame: CGRect.zero)
        recordView.tintColor = NSColor(red: 0.164, green: 0.517, blue: 0.823, alpha: 1)
        recordView.delegate = context.coordinator
        recordView.layer?.cornerRadius = 6.0
        recordView.layer?.masksToBounds = true
        return recordView
    }

    func updateNSView(_: NSViewType, context _: Context) {}
}

extension GeneralKeyHolderWrapper {
    class Coordinator: NSObject, RecordViewDelegate {
        func recordViewShouldBeginRecording(_: KeyHolder.RecordView) -> Bool {
            true
        }

        func recordView(_: KeyHolder.RecordView, canRecordKeyCombo _: Magnet.KeyCombo) -> Bool {
            true
        }

        func recordView(_: KeyHolder.RecordView, didChangeKeyCombo _: Magnet.KeyCombo?) {}

        func recordViewDidEndRecording(_: KeyHolder.RecordView) {}
    }
}
