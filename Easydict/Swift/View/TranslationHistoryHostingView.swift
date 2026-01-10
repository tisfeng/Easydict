//
//  TranslationHistoryHostingView.swift
//  Easydict
//
//  Created by Ryan on 2026/01/10.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SwiftUI

// MARK: - TranslationHistoryHostingView

/// NSViewController wrapper for TranslationHistoryView to be used in Objective-C code.
@objc(EZTranslationHistoryHostingView)
public class TranslationHistoryHostingView: NSViewController {
    // MARK: Lifecycle

    @objc(initWithOnSelectHistory:)
    public init(onSelectHistory: @escaping (String, String) -> ()) {
        self.onSelectHistoryCallback = onSelectHistory
        super.init(nibName: nil, bundle: nil)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    /// Updates the history view.
    public func refresh() {
        // Trigger view update if needed
    }

    // MARK: Private

    private let onSelectHistoryCallback: (String, String) -> ()
    private var hostingView: NSHostingView<TranslationHistoryViewWrapper>?

    private func setupView() {
        let wrapper = TranslationHistoryViewWrapper { [weak self] item in
            self?.onSelectHistoryCallback(item.queryText, item.translatedText)
        }
        let hostingView = NSHostingView(rootView: wrapper)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Create a container view with proper frame
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 600))
        containerView.addSubview(hostingView)

        // Set up constraints
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        view = containerView
        self.hostingView = hostingView
    }
}

// MARK: - TranslationHistoryViewWrapper

/// Wrapper view to handle history selection callback.
public struct TranslationHistoryViewWrapper: View {
    // MARK: Lifecycle

    public init(onSelectHistory: @escaping (TranslationHistoryItem) -> ()) {
        self.onSelectHistory = onSelectHistory
    }

    // MARK: Public

    public let onSelectHistory: (TranslationHistoryItem) -> ()

    public var body: some View {
        TranslationHistoryView(onSelectHistory: onSelectHistory)
    }

    public func refresh() {
        // Trigger view update
    }
}
