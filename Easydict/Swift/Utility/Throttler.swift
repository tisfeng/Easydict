//
//  Throttler.swift
//  Easydict
//
//  Created by tisfeng on 2024/5/9.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

class Throttler {
    // MARK: Lifecycle

    init(maxInterval: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.maxInterval = maxInterval
        self.queue = queue
    }

    // MARK: Internal

    func throttle(block: @escaping () -> ()) {
        workItem.cancel()
        workItem = DispatchWorkItem { [weak self] in
            self?.previousRun = Date()
            block()
        }

        let timeSinceLastRun = -previousRun.timeIntervalSinceNow
        let delay = timeSinceLastRun > maxInterval ? 0 : maxInterval - timeSinceLastRun
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    // MARK: Private

    private var workItem: DispatchWorkItem = .init(block: {})
    private var previousRun: Date = .distantPast
    private let queue: DispatchQueue
    private var maxInterval: TimeInterval
}
