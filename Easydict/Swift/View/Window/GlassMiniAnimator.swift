//
//  GlassMiniAnimator.swift
//  Easydict
//

import AppKit

/// Animates the real window bounds so invisible areas never cover the document beneath it.
@MainActor
final class GlassMiniAnimator {
    private var timer: Timer?
    private(set) var isAnimating = false

    func cancel() {
        timer?.invalidate()
        timer = nil
        isAnimating = false
    }

    func resize(_ window: NSWindow, to size: NSSize, animated: Bool, completion: @escaping () -> Void) {
        cancel()
        let start = window.frame
        let screen = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? start
        let target = safeFrame(size: size, anchor: start, screen: screen)
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            window.setFrame(target, display: true)
            completion()
            return
        }

        let began = ProcessInfo.processInfo.systemUptime
        isAnimating = true
        let timer = Timer(timeInterval: 1 / 60, repeats: true) { [weak self, weak window] _ in
            MainActor.assumeIsolated {
                guard let self, let window else { return }
                let elapsed = ProcessInfo.processInfo.systemUptime - began
                // A damped spring with a small overshoot, settled after 0.46 seconds.
                let progress = 1 - exp(-12 * elapsed) * (cos(15 * elapsed) + 0.8 * sin(15 * elapsed))
                let currentSize = NSSize(
                    width: start.width + (target.width - start.width) * progress,
                    height: start.height + (target.height - start.height) * progress
                )
                window.setFrame(self.safeFrame(size: currentSize, anchor: start, screen: screen), display: true)
                if elapsed >= 0.46 {
                    self.cancel()
                    window.setFrame(target, display: true)
                    completion()
                }
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func safeFrame(size: NSSize, anchor: NSRect, screen: NSRect) -> NSRect {
        let width = min(size.width, screen.width)
        let height = min(size.height, screen.height)
        return NSRect(
            x: min(max(anchor.minX, screen.minX), screen.maxX - width),
            y: min(max(anchor.maxY - height, screen.minY), screen.maxY - height),
            width: width, height: height
        )
    }
}
