//
//  TapHandlerView.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/10.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// Ref: https://stackoverflow.com/a/64194868/8378840
// Fix conflicts between onTap and onMove modifier
class TapHandlerView: NSView {
    var tapAction: () -> Void

    init(_ block: @escaping () -> Void) {
        tapAction = block
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        tapAction()
    }
}

struct TapHandler: NSViewRepresentable {
    let tapAction: () -> Void

    func makeNSView(context _: Context) -> TapHandlerView {
        TapHandlerView(tapAction)
    }

    func updateNSView(_ nsView: TapHandlerView, context _: Context) {
        nsView.tapAction = tapAction
    }
}
