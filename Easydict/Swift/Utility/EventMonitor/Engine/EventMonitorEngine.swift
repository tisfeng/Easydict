//
//  EventMonitorEngine.swift
//  Easydict
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - EventScope

/// The monitor that received the event.
enum EventScope {
    case local
    case global
}

// MARK: - EventMonitorEngine

/// Handles NSEvent monitor lifecycle and dispatch.
final class EventMonitorEngine {
    // MARK: Internal

    /// Defines the monitor scope to use for NSEvent tracking.
    enum MonitorType {
        case local
        case global
        case both
    }

    /// Configures the monitor type, mask, and event handler, then starts monitoring.
    /// - Parameters:
    ///   - type: Monitor scope to install.
    ///   - mask: Event mask to observe.
    ///   - handler: Handler invoked for each matching event.
    func monitor(type: MonitorType, mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent, EventScope) -> ()) {
        self.type = type
        self.mask = mask
        self.handler = handler
        start()
    }

    /// Starts monitors based on the current configuration.
    func start() {
        stop()
        guard let handler else { return }

        switch type {
        case .local:
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
                handler(event, .local)
                return event
            }
        case .global:
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
                handler(event, .global)
            }
        case .both:
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
                handler(event, .local)
                return event
            }
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { event in
                handler(event, .global)
            }
        }
    }

    /// Stops and clears any active monitors.
    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
    }

    // MARK: Private

    private var type: MonitorType = .local
    private var mask: NSEvent.EventTypeMask = []
    private var handler: ((NSEvent, EventScope) -> ())?

    private var localMonitor: Any?
    private var globalMonitor: Any?
}
