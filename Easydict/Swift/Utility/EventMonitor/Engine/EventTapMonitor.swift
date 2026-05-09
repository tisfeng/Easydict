//
//  EventTapMonitor.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - EventTapMonitor

/// Uses CGEventTap to monitor global key events not covered by NSEvent monitors.
///
/// - Important: The CGEventTap callback uses `Unmanaged.passUnretained(self)` as
///   its refcon. Therefore this instance MUST outlive every `start()` call until a
///   matching `stop()` returns; otherwise the callback dereferences a freed pointer.
///   Currently safe because the only owner is `EventMonitor.shared` (singleton).
/// - Important: `start()` and `stop()` mutate three CF state fields without locks,
///   so they MUST be invoked on the main thread. The callback also runs on the main
///   run loop because the source is installed on `CFRunLoopGetMain()`.
final class EventTapMonitor {
    // MARK: Internal

    /// Invoked when a key-down event is observed by the event tap.
    var keyDownHandler: ((CGKeyCode, CGEventFlags) -> ())?

    /// Starts the CGEventTap for global keyboard events.
    ///
    /// Always installs the run loop source on the main run loop to avoid
    /// mismatched add/remove when `start()` and `stop()` are called from
    /// different threads (e.g. Swift concurrency Task vs main-thread callback).
    func start() {
        dispatchPrecondition(condition: .onQueue(.main))

        stop()

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<EventTapMonitor>.fromOpaque(refcon).takeUnretainedValue()
            switch type {
            case .keyDown:
                let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
                let flags = event.flags
                DispatchQueue.main.async {
                    monitor.keyDownHandler?(keyCode, flags)
                }
            case .tapDisabledByTimeout, .tapDisabledByUserInput:
                if let tap = monitor.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
            default:
                break
            }
            return Unmanaged.passUnretained(event)
        }

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap else { return }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        runLoopSource = source
        let mainRunLoop = CFRunLoopGetMain()
        installedRunLoop = mainRunLoop
        CFRunLoopAddSource(mainRunLoop, source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    /// Stops the CGEventTap and removes the run loop source.
    func stop() {
        dispatchPrecondition(condition: .onQueue(.main))

        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource, let installedRunLoop {
                CFRunLoopRemoveSource(installedRunLoop, runLoopSource, .commonModes)
            }
            CFMachPortInvalidate(eventTap)
            runLoopSource = nil
            installedRunLoop = nil
            self.eventTap = nil
        }
    }

    // MARK: Private

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var installedRunLoop: CFRunLoop?
}
