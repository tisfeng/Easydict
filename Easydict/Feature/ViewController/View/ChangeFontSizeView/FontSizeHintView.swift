//
//  FontSizeHintView.swift
//  Easydict
//
//  Created by yqing on 2023/12/22.
//  Copyright © 2023 izual. All rights reserved.
//

import AppKit
import Foundation

@objc public class FontSizeHintView: NSView {
    private lazy var minLabel: NSTextField = .init(labelWithString: NSLocalizedString("small", comment: ""))

    private lazy var maxLabel: NSTextField = .init(labelWithString: NSLocalizedString("large", comment: ""))

    private lazy var hintLabel: NSTextField = .init(wrappingLabelWithString: NSLocalizedString("hints_keyboard_shortcuts_font_size", comment: ""))

    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        minLabel.font = .systemFont(ofSize: 10)
        maxLabel.font = .systemFont(ofSize: 14)

        hintLabel.font = .systemFont(ofSize: 11)

        let sizeLabelStackView: NSStackView = {
            let stackView = NSStackView(views: [minLabel, maxLabel])
            stackView.alignment = .centerY
            stackView.distribution = .equalSpacing
            stackView.orientation = .horizontal
            return stackView
        }()

        let verticalStackView: NSStackView = {
            let stackView = NSStackView(views: [sizeLabelStackView, hintLabel])
            stackView.alignment = .left
            stackView.distribution = .fill
            stackView.orientation = .vertical
            stackView.spacing = 12
            return stackView
        }()

        addSubview(verticalStackView)

        NSLayoutConstraint.activate([
            sizeLabelStackView.widthAnchor.constraint(equalToConstant: 205),
            sizeLabelStackView.heightAnchor.constraint(equalToConstant: 20),
        ])

        NSLayoutConstraint.activate([
            verticalStackView.leftAnchor.constraint(equalTo: leftAnchor),
            verticalStackView.topAnchor.constraint(equalTo: topAnchor),
            verticalStackView.rightAnchor.constraint(equalTo: rightAnchor),
        ])

        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
