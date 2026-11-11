//
//  MarkdownToggleButton.swift
//  Easydict
//
//  Created by Lin on 2026/4/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SFSafeSymbols

/// Switches between rendered Markdown and its source.
@objc(EDMarkdownToggleButton)
final class MarkdownToggleButton: EZHoverButton {
    // MARK: Lifecycle

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    // MARK: Internal

    /// Callback invoked when the user clicks the button. Set from the host
    /// view to refresh the result with the toggled state.
    @objc var clickAction: (() -> ())?

    /// Whether Markdown rendering is currently active for the owning result.
    /// Drives the icon color and the accessibility / tooltip strings.
    @objc var markdownEnabled: Bool = true {
        didSet {
            guard oldValue != markdownEnabled else { return }
            applyVisualState()
        }
    }

    // MARK: Private

    private func configure() {
        cornerRadius = 5
        image = NSImage(systemSymbol: .docRichtext)

        clickBlock = { [weak self] _ in
            self?.clickAction?()
        }

        executeOnAppearanceChange { [weak self] _, _ in
            self?.applyVisualState()
        }
    }

    private func applyVisualState() {
        let onColor: NSColor = isDarkMode
            ? .ez_imageTintDark()
            : .ez_imageTintLight()
        let offColor = onColor.withAlphaComponent(0.35)

        contentTintColor = markdownEnabled ? onColor : offColor

        toolTip = markdownEnabled
            ? String(localized: "markdown.toggle.tooltip.on")
            : String(localized: "markdown.toggle.tooltip.off")
    }
}
