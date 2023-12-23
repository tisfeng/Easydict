//
//  FontSizeHintView.swift
//  Easydict
//
//  Created by yqing on 2023/12/22.
//  Copyright © 2023 izual. All rights reserved.
//

import AppKit
import Foundation
import Hue
import SnapKit

@objc public class FontSizeHintView: NSView {
    private lazy var minLabel: NSTextField = .init(labelWithString: NSLocalizedString("small", comment: ""))
    private lazy var maxLabel: NSTextField = .init(labelWithString: NSLocalizedString("large", comment: ""))
    private lazy var hintLabel: NSTextField = .init(wrappingLabelWithString: NSLocalizedString("hints_keyboard_shortcuts_font_size", comment: ""))

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        minLabel.font = .systemFont(ofSize: 10)
        maxLabel.font = .systemFont(ofSize: 14)
        hintLabel.font = .systemFont(ofSize: 11)
        hintLabel.textColor = NSColor(hex: "7B7C7C")

        addSubview(minLabel)
        addSubview(maxLabel)
        addSubview(hintLabel)

        hintLabel.snp.makeConstraints { make in
            make.left.bottom.equalTo(self)
        }

        maxLabel.snp.makeConstraints { make in
            make.right.top.equalTo(self)
        }

        minLabel.snp.makeConstraints { make in
            make.left.equalTo(self)
            make.centerY.equalTo(maxLabel)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
