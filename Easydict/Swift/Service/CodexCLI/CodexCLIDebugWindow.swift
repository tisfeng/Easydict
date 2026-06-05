//
//  CodexCLIDebugWindow.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

#if AGENT_CLI_DEBUG
import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - CodexCLIDebugWindowController

/// Manages the floating debug log panel for Codex CLI output.
///
/// Open via the "Show Debug Log Window" button in the Codex CLI service settings.
/// Visible only in AGENT_CLI_DEBUG builds.
final class CodexCLIDebugWindowController: NSWindowController {
    // MARK: Lifecycle

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = String(localized: "service.codex_cli.debug_log.window_title")
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.contentView = NSHostingView(rootView: CodexCLIDebugView())
        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static let shared = CodexCLIDebugWindowController()

    func toggle() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - CodexCLIDebugViewModel

@MainActor
private final class CodexCLIDebugViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        NotificationCenter.default
            .publisher(for: CodexCLIDebugLogger.didAppendNotification)
            .compactMap { $0.userInfo?[CodexCLIDebugLogger.textKey] as? String }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.logText += text
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    @Published var logText = ""

    var currentLogDirectory: URL? {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "Easydict")
            .appendingPathComponent("logs")
            .appendingPathComponent("codex-cli")
    }

    func clear() { logText = "" }

    func showInFinder() {
        guard let url = currentLogDirectory else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: Private

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - CodexCLIDebugView

private struct CodexCLIDebugView: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("service.codex_cli.debug_log.clear") { viewModel.clear() }
                Button("service.codex_cli.debug_log.show_in_finder") { viewModel.showInFinder() }
                Spacer()
            }
            .padding(8)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    Text(viewModel.logText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .id("bottom")
                }
                .onChange(of: viewModel.logText) { _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: Private

    @StateObject private var viewModel = CodexCLIDebugViewModel()
}
#endif
