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
final class EventTapMonitor {
    // MARK: Internal

    /// Invoked when a key-down event is observed by the event tap.
    var keyDownHandler: ((CGKeyCode, CGEventFlags) -> ())?

    /// Starts the CGEventTap for global keyboard events.
    func start() {
        stop()

        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<EventTapMonitor>.fromOpaque(refcon).takeUnretainedValue()
            let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
            switch type {
            case .keyDown:
                monitor.keyDownHandler?(keyCode, event.flags)
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
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    /// Stops the CGEventTap and removes the run loop source.
    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            runLoopSource = nil
            self.eventTap = nil
        }
    }

    // MARK: Private

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
}
