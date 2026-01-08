//
//  EventMonitorEngine.swift
//  Scoco
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

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

    /// Receives every event delivered by the active monitors.
    var eventHandler: ((NSEvent) -> ())?

    /// Configures the monitor type, mask, and event handler, then starts monitoring.
    /// - Parameters:
    ///   - type: Monitor scope to install.
    ///   - mask: Event mask to observe.
    ///   - handler: Handler invoked for each matching event.
    func monitor(type: MonitorType, mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> ()) {
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
                handler(event)
                return event
            }
        case .global:
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
        case .both:
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
                handler(event)
                return event
            }
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
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
    private var handler: ((NSEvent) -> ())?

    private var localMonitor: Any?
    private var globalMonitor: Any?
}
