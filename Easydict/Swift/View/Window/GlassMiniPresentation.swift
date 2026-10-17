//
//  GlassMiniPresentation.swift
//  Easydict
//

import AppKit
import SwiftUI

/// Bridges the existing query lifecycle to the optional translation-only mini presentation.
@MainActor
@objcMembers
final class GlassMiniPresentation: NSObject {
    init(window: EZBaseQueryWindow, parent: NSViewController) {
        self.window = window
        self.parent = parent
        originalStyle = window.styleMask
        originalMinimum = window.minSize
        originalFrame = window.frame
        super.init()

        let host = NSHostingView(rootView: GlassMiniView(
            state: state,
            pin: { [weak window, weak self] in
                guard let window else { return }
                window.isPin.toggle()
                self?.updatePin()
            },
            retry: { [weak window] in
                guard let controller = window?.queryViewController else { return }
                controller.startQueryText(controller.inputText, actionType: controller.queryModel.actionType)
            },
            copy: { [weak self] in
                guard let self else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(state.text, forType: .string)
            },
            close: { EZWindowManager.shared().closeFloating(.mini) }
        ))
        hostingView = host
        host.focusRingType = .none
        host.sizingOptions = []
        host.translatesAutoresizingMaskIntoConstraints = false
        parent.view.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
            host.topAnchor.constraint(equalTo: parent.view.topAnchor),
            host.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor),
        ])
        window.titleBar.isHidden = true
        window.styleMask = [.borderless, .nonactivatingPanel]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.minSize = .zero
        parent.view.layer?.backgroundColor = NSColor.clear.cgColor
        parent.view.layer?.masksToBounds = false
        updatePin()
        showReady()
    }

    func detach() {
        resultTask?.cancel()
        animator.cancel()
        hostingView?.removeFromSuperview()
        guard let window else { return }
        window.styleMask = originalStyle
        window.minSize = originalMinimum
        window.isOpaque = true
        window.hasShadow = true
        window.titleBar.isHidden = false
        window.setFrame(originalFrame, display: true)
        parent?.view.layer?.masksToBounds = true
    }

    func updatePin() {
        state.pinned = window?.isPin ?? false
    }

    func showReady() {
        resultTask?.cancel()
        state.phase = .ready
        state.text = NSLocalizedString("glass.mini.ready", comment: "")
        state.provider = ""
        showContent(animated: false)
    }

    func beginLoading() {
        resultTask?.cancel()
        state.phase = .loading
        state.text = ""
        state.provider = ""
        state.contentVisible = false
        guard let window else { return }
        animator.resize(window, to: NSSize(width: 110, height: 62), animated: false) {}
    }

    func showUnavailableService() {
        showError(NSLocalizedString("glass.mini.unavailable", comment: ""))
    }

    func showError(_ message: String) {
        resultTask?.cancel()
        state.phase = .failure
        state.text = message
        showContent(animated: true)
    }

    func updateResult(_ result: QueryResult, service: QueryService) {
        guard result.isShowing else { return }
        state.provider = service.name()
        if let error = result.error {
            result.isLoading = false
            showError(error.localizedDescription)
            return
        }
        // Buffer streaming services until completion, then expand only once.
        guard !service.isStream() || result.isStreamFinished else { return }
        result.isLoading = false
        resultTask?.cancel()
        if let text = GlassMiniResultText.plainText(from: result) {
            showResult(text)
            return
        }

        // Pass only value snapshots across threads; QueryResult belongs to the query lifecycle.
        let fragments = result.htmlStrings?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
        let html = fragments.isEmpty ? [result.htmlString ?? ""] : fragments
        resultTask = Task { [weak self] in
            let text = await Task.detached(priority: .userInitiated) {
                GlassMiniResultText.htmlText(from: html)
            }.value
            // A newer query, service change, mode switch, or close invalidates this result.
            guard !Task.isCancelled else { return }
            self?.showResult(text)
        }
    }

    func cancelAnimation() {
        resultTask?.cancel()
        animator.cancel()
        state.contentVisible = true
        if state.phase == .loading {
            showReady()
        }
    }

    private weak var window: EZBaseQueryWindow?
    private weak var parent: NSViewController?
    private var hostingView: NSView?
    private var resultTask: Task<Void, Never>?
    private let state = GlassMiniState()
    private let animator = GlassMiniAnimator()
    private let originalStyle: NSWindow.StyleMask
    private let originalMinimum: NSSize
    private let originalFrame: NSRect

    private func showResult(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(NSLocalizedString("glass.mini.no_result", comment: ""))
            return
        }
        state.phase = .result
        state.text = text
        showContent(animated: true)
    }

    private func showContent(animated: Bool) {
        guard let window else { return }
        let screen = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? window.frame
        let width = min(410, screen.width - 24)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let bounds = (state.text as NSString).boundingRect(
            with: NSSize(width: width - 86, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: NSFont.systemFont(ofSize: 16), .paragraphStyle: paragraph]
        )
        let height = min(max(ceil(bounds.height) + 90, 124), screen.height * 0.65)
        state.contentVisible = !animated
        animator.resize(window, to: NSSize(width: width, height: height), animated: animated) { [weak self] in
            guard let self else { return }
            let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
                self.state.contentVisible = true
            }
        }
    }
}
