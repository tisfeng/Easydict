//
//  TriggerEvaluator.swift
//  Scoco
//
//  Created by tisfeng on 2025/xx/xx.
//  Copyright © 2025 izual. All rights reserved.
//

import AppKit
import Foundation

// MARK: - TriggerEvaluator

/// Tracks recent events to infer trigger gestures.
final class TriggerEvaluator {
    // MARK: Internal

    var onTrigger: ((EZTriggerType) -> ())?

    func updateRecordedEvents(_ event: NSEvent) {
        if recordedEvents.count >= Constants.recordEventCount {
            recordedEvents.removeFirst()
        }
        recordedEvents.append(event)
    }

    func checkIfLeftMouseDragged() -> Bool {
        guard recordedEvents.count >= Constants.recordEventCount else {
            return false
        }
        return recordedEvents.allSatisfy { $0.type == .leftMouseDragged }
    }

    func updateCommandKeyEvents(_ event: NSEvent) {
        if commandKeyEvents.count >= Constants.commandKeyEventCount {
            commandKeyEvents.removeFirst()
        }
        commandKeyEvents.append(event)
    }

    func checkIfDoubleCommandEvents() -> Bool {
        guard commandKeyEvents.count >= Constants.commandKeyEventCount else {
            return false
        }
        guard let firstEvent = commandKeyEvents.first,
              let lastEvent = commandKeyEvents.last else {
            return false
        }
        let interval = lastEvent.timestamp - firstEvent.timestamp
        return interval < Constants.doubleCommandInterval
    }

    // MARK: Private

    private enum Constants {
        static let recordEventCount = 3
        static let commandKeyEventCount = 4
        static let doubleCommandInterval: TimeInterval = 0.5
    }

    private var recordedEvents: [NSEvent] = []
    private var commandKeyEvents: [NSEvent] = []
}
