//
//  ScreenshotKeyboardEventTap.swift
//  Easydict
//
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit

/// Isolates screenshot input without making the overlay a key window.
/// All state belongs to the main run loop. Consumed keys are drained through
/// key-up even after capture ends, so held keys cannot leak into another app.
final class ScreenshotKeyboardEventTap {
    // MARK: Lifecycle

    deinit {
        invalidate()
    }

    // MARK: Internal

    /// A system switching shortcut can cancel capture while keeping its event.
    struct Action {
        var consumesEvent = true
        let perform: () -> ()
    }

    @discardableResult
    func start(onFailure: @escaping () -> (), actionProvider: @escaping (NSEvent) -> Action) -> Bool {
        dispatchPrecondition(condition: .onQueue(.main))
        if eventTap == nil {
            let mask = CGEventMask((1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue))
            let callback: CGEventTapCallBack = { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<ScreenshotKeyboardEventTap>.fromOpaque(userInfo).takeUnretainedValue()
                return monitor.handleEvent(type: type, event: event)
            }
            guard let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: mask,
                callback: callback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            ) else { return false }
            guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
                CFMachPortInvalidate(port)
                return false
            }
            eventTap = port
            runLoopSource = source
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        }
        guard enableTap() else {
            reset()
            return false
        }
        sessionID = UUID()
        self.actionProvider = actionProvider
        self.onFailure = onFailure
        return true
    }

    /// Stops accepting new input, retaining only ownership of consumed keys.
    func finish() {
        dispatchPrecondition(condition: .onQueue(.main))
        sessionID = nil
        actionProvider = nil
        onFailure = nil
        invalidateIfIdle()
    }

    // MARK: Private

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var sessionID: UUID?
    private var actionProvider: ((NSEvent) -> Action)?
    private var onFailure: (() -> ())?
    private var consumedKeys: Set<CGKeyCode> = []

    private func enableTap() -> Bool {
        guard let eventTap else { return false }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            guard eventTap != nil else { return Unmanaged.passUnretained(event) }
            guard enableTap() else {
                let failure = onFailure
                reset()
                DispatchQueue.main.async { failure?() }
                return Unmanaged.passUnretained(event)
            }
            // Re-enable delivery before sampling to avoid missing another release.
            consumedKeys = consumedKeys.filter { CGEventSource.keyState(.hidSystemState, key: $0) }
            invalidateIfIdle()
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown || type == .keyUp else { return Unmanaged.passUnretained(event) }
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let isPressed = type == .keyDown
        let isRepeat = isPressed && event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        if isPressed, !isRepeat {
            // A new physical press proves a previous release was missed.
            consumedKeys.remove(keyCode)
            invalidateIfIdle()
        }
        if consumedKeys.contains(keyCode) {
            if !isPressed {
                consumedKeys.remove(keyCode)
                invalidateIfIdle()
            }
            return nil
        }

        // Keys held before capture retain their original target and paired release.
        guard isPressed, !isRepeat, let sessionID, let actionProvider,
              let nsEvent = NSEvent(cgEvent: event) else { return Unmanaged.passUnretained(event) }
        let action = actionProvider(nsEvent)
        if action.consumesEvent {
            consumedKeys.insert(keyCode)
        }
        // Window teardown and capture must never execute inside the tap callback.
        DispatchQueue.main.async { [weak self] in
            guard self?.sessionID == sessionID else { return }
            action.perform()
        }
        return action.consumesEvent ? nil : Unmanaged.passUnretained(event)
    }

    private func invalidateIfIdle() {
        if actionProvider == nil, consumedKeys.isEmpty {
            invalidate()
        }
    }

    private func reset() {
        sessionID = nil
        actionProvider = nil
        onFailure = nil
        consumedKeys.removeAll()
        invalidate()
    }

    private func invalidate() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }
}
