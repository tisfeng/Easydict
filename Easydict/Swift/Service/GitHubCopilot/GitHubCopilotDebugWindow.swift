//
//  GitHubCopilotDebugWindow.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

#if AGENT_CLI_DEBUG
import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - GitHubCopilotDebugWindowController

/// Manages the floating debug log panel for GitHub Copilot CLI output.
///
/// Open via the "Show Debug Log Window" button in the GitHub Copilot service settings.
/// Visible only in AGENT_CLI_DEBUG builds.
final class GitHubCopilotDebugWindowController: NSWindowController {
    // MARK: Lifecycle

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = String(localized: "service.github_copilot.debug_log.window_title")
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.contentView = NSHostingView(rootView: GitHubCopilotDebugView())
        super.init(window: panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static let shared = GitHubCopilotDebugWindowController()

    func toggle() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - GitHubCopilotDebugViewModel

@MainActor
private final class GitHubCopilotDebugViewModel: ObservableObject {
    // MARK: Lifecycle

    init() {
        NotificationCenter.default
            .publisher(for: GitHubCopilotDebugLogger.didAppendNotification)
            .compactMap { $0.userInfo?[GitHubCopilotDebugLogger.textKey] as? String }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.logText += text
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    @Published var logText = ""

    var currentLogDirectory: URL? {
        AppPathManager.current.githubCopilotLogDirectory
    }

    func clear() { logText = "" }

    func showInFinder() {
        guard let url = currentLogDirectory else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: Private

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - GitHubCopilotDebugView

private struct GitHubCopilotDebugView: View {
    // MARK: Internal

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("service.github_copilot.debug_log.clear") { viewModel.clear() }
                Button("service.github_copilot.debug_log.show_in_finder") { viewModel.showInFinder() }
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

    @StateObject private var viewModel = GitHubCopilotDebugViewModel()
}
#endif
