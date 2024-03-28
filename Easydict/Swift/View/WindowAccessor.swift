//
//  WindowAccessor.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/9.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context _: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            window = view.window
        }
        return view
    }

    func updateNSView(_: NSView, context _: Context) {}
}
