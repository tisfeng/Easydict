//
//  GeneralKeyHolderWrapper.swift
//  Easydict
//
//  Created by Sharker on 2024/1/2.
//  Copyright © 2024 izual. All rights reserved.
//

import AppKit
import KeyHolder
import SwiftUI

struct GeneralKeyHolderWrapper: NSViewRepresentable {
    func makeNSView(context _: Context) -> some NSView {
        let recordView = RecordView(frame: CGRect.zero)
        recordView.tintColor = NSColor(red: 0.164, green: 0.517, blue: 0.823, alpha: 1)
        recordView.layer?.cornerRadius = 6.0
        recordView.layer?.masksToBounds = true
        return recordView
    }

    func updateNSView(_: NSViewType, context _: Context) {}
}
