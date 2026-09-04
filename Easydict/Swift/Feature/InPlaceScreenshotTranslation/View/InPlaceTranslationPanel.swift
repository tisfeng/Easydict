//
//  InPlaceTranslationPanel.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Carbon
import SwiftUI

// MARK: - InPlaceTranslationPanel

/// A persistent, resizable translation panel that remains visible on app
/// deactivation and is excluded from all screen-sharing capture.
final class InPlaceTranslationPanel: NSPanel, NSWindowDelegate {
    // MARK: Lifecycle

    init(viewModel: InPlaceTranslationViewModel, selection: ScreenshotSelection) {
        self.viewModel = viewModel
        super.init(
            contentRect: .zero,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        title = String(localized: "in_place_screenshot_translation.window.title")
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        sharingType = .none
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        minSize = CGSize(width: 360, height: 220)
        delegate = self
        setPinned(viewModel.configuration.isPinned)

        contentView = NSHostingView(
            rootView: InPlaceTranslationContentView(
                viewModel: viewModel,
                placeholderImage: selection.initialImage
            )
        )
        setFrame(Self.initialFrame(for: selection), display: false)
    }

    // MARK: Internal

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    var onRequestClose: (() -> ())?
    var onMiniaturize: (() -> ())?
    var onDeminiaturize: (() -> ())?

    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = Int(event.keyCode)
        if modifiers.contains(.command), keyCode == kVK_ANSI_R {
            viewModel.refresh()
            return
        }
        if modifiers.contains(.command), keyCode == kVK_ANSI_C {
            viewModel.copyTranslation()
            return
        }
        if modifiers.isEmpty {
            switch keyCode {
            case kVK_Space:
                viewModel.showOriginalTemporarily(true)
                return
            case kVK_ANSI_T:
                viewModel.toggleRenderMode()
                return
            case kVK_ANSI_L:
                viewModel.setLiveUpdatesEnabled(
                    !viewModel.configuration.liveUpdatesEnabled
                )
                return
            case kVK_Escape:
                performClose(nil)
                return
            default:
                break
            }
        }
        super.keyDown(with: event)
    }

    override func keyUp(with event: NSEvent) {
        if Int(event.keyCode) == kVK_Space {
            viewModel.showOriginalTemporarily(false)
            return
        }
        super.keyUp(with: event)
    }

    func setPinned(_ pinned: Bool) {
        level = pinned ? .floating : .normal
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        onRequestClose?()
        return true
    }

    func windowDidMiniaturize(_ notification: Notification) {
        onMiniaturize?()
    }

    func windowDidDeminiaturize(_ notification: Notification) {
        onDeminiaturize?()
    }

    // MARK: Private

    private let viewModel: InPlaceTranslationViewModel

    private static func initialFrame(for selection: ScreenshotSelection) -> CGRect {
        let screen = NSScreen.screens.first { $0.displayID == selection.displayID }
        let visibleFrame = screen?.visibleFrame ?? NSScreen.main?.visibleFrame
            ?? selection.screenFrameInGlobalPoints
        let toolbarHeight: CGFloat = 88
        let requestedSize = CGSize(
            width: selection.sourceRectInDisplayPoints.width,
            height: selection.sourceRectInDisplayPoints.height + toolbarHeight
        )
        let maximumSize = CGSize(
            width: visibleFrame.width * 0.7,
            height: visibleFrame.height * 0.7
        )
        let scale = min(
            1,
            maximumSize.width / max(1, requestedSize.width),
            maximumSize.height / max(1, requestedSize.height)
        )
        let size = CGSize(
            width: max(360, requestedSize.width * scale),
            height: max(220, requestedSize.height * scale)
        )
        var origin = CGPoint(
            x: selection.globalFrameInScreenPoints.minX,
            y: selection.globalFrameInScreenPoints.minY - toolbarHeight * scale
        )
        origin.x = min(max(origin.x, visibleFrame.minX), visibleFrame.maxX - size.width)
        origin.y = min(max(origin.y, visibleFrame.minY), visibleFrame.maxY - size.height)
        return CGRect(origin: origin, size: size)
    }
}
