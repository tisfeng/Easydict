//
//  OpenAIStreamTaskControlTests.swift
//  EasydictTests
//
//  Created by tisfeng on 2026/9/8.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

/// Tests the task lifecycle that bridges Easydict cancellation to the stream consumer.
@Suite("OpenAI Stream Task Control", .tags(.unit))
struct OpenAIStreamTaskControlTests {
    // MARK: Internal

    @Test("Cancellation before installation cancels the later task")
    func cancellationBeforeInstallCancelsLaterTask() {
        let control = OpenAIStreamTaskControl()
        let identifier = UUID()

        control.begin(identifier: identifier)
        control.cancel(identifier: identifier)

        let task = waitingTask()
        control.install(task, identifier: identifier)

        #expect(task.isCancelled)
    }

    @Test("Beginning a replacement request cancels the active task")
    func beginningReplacementRequestCancelsActiveTask() {
        let control = OpenAIStreamTaskControl()
        let firstIdentifier = UUID()
        control.begin(identifier: firstIdentifier)

        let firstTask = waitingTask()
        control.install(firstTask, identifier: firstIdentifier)

        let secondIdentifier = UUID()
        control.begin(identifier: secondIdentifier)
        defer { control.cancel() }

        #expect(firstTask.isCancelled)
    }

    @Test("Finishing a stale request preserves cancellation of the active task")
    func finishingStaleRequestPreservesActiveTaskCancellation() {
        let control = OpenAIStreamTaskControl()
        let staleIdentifier = UUID()
        control.begin(identifier: staleIdentifier)

        let staleTask = waitingTask()
        control.install(staleTask, identifier: staleIdentifier)

        let activeIdentifier = UUID()
        control.begin(identifier: activeIdentifier)
        let activeTask = waitingTask()
        control.install(activeTask, identifier: activeIdentifier)

        control.finish(identifier: staleIdentifier)

        #expect(!activeTask.isCancelled)

        control.cancel()

        #expect(activeTask.isCancelled)
    }

    // MARK: Private

    private func waitingTask() -> Task<(), Never> {
        Task {
            try? await Task.sleep(nanoseconds: .max)
        }
    }
}
