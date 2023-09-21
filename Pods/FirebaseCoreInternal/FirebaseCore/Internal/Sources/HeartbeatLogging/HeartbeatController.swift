// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// An object that provides API to log and flush heartbeats from a synchronized storage container.
public final class HeartbeatController {
  /// The thread-safe storage object to log and flush heartbeats from.
  private let storage: HeartbeatStorageProtocol
  /// The max capacity of heartbeats to store in storage.
  private let heartbeatsStorageCapacity: Int = 30
  /// Current date provider. It is used for testability.
  private let dateProvider: () -> Date
  /// Used for standardizing dates for calendar-day comparision.
  static let dateStandardizer: (Date) -> (Date) = {
    var calendar = Calendar(identifier: .iso8601)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar.startOfDay(for:)
  }()

  /// Public initializer.
  /// - Parameter id: The `id` to associate this controller's heartbeat storage with.
  public convenience init(id: String) {
    self.init(id: id, dateProvider: Date.init)
  }

  /// Convenience initializer. Mirrors the semantics of the public initializer with the added
  /// benefit of
  /// injecting a custom date provider for improved testability.
  /// - Parameters:
  ///   - id: The id to associate this controller's heartbeat storage with.
  ///   - dateProvider: A date provider.
  convenience init(id: String, dateProvider: @escaping () -> Date) {
    let storage = HeartbeatStorage.getInstance(id: id)
    self.init(storage: storage, dateProvider: dateProvider)
  }

  /// Designated initializer.
  /// - Parameters:
  ///   - storage: A heartbeat storage container.
  ///   - dateProvider: A date provider. Defaults to providing the current date.
  init(storage: HeartbeatStorageProtocol,
       dateProvider: @escaping () -> Date = Date.init) {
    self.storage = storage
    self.dateProvider = { Self.dateStandardizer(dateProvider()) }
  }

  /// Asynchronously logs a new heartbeat, if needed.
  ///
  /// - Note: This API is thread-safe.
  /// - Parameter agent: The string agent (i.e. Firebase User Agent) to associate the logged
  /// heartbeat with.
  public func log(_ agent: String) {
    let date = dateProvider()

    storage.readAndWriteAsync { heartbeatsBundle in
      var heartbeatsBundle = heartbeatsBundle ??
        HeartbeatsBundle(capacity: self.heartbeatsStorageCapacity)

      // Filter for the time periods where the last heartbeat to be logged for
      // that time period was logged more than one time period (i.e. day) ago.
      let timePeriods = heartbeatsBundle.lastAddedHeartbeatDates.filter { timePeriod, lastDate in
        date.timeIntervalSince(lastDate) >= timePeriod.timeInterval
      }
      .map { timePeriod, _ in timePeriod }

      if !timePeriods.isEmpty {
        // A heartbeat should only be logged if there is a time period(s) to
        // associate it with.
        let heartbeat = Heartbeat(agent: agent, date: date, timePeriods: timePeriods)
        heartbeatsBundle.append(heartbeat)
      }

      return heartbeatsBundle
    }
  }

  /// Synchronously flushes heartbeats from storage into a heartbeats payload.
  ///
  /// - Note: This API is thread-safe.
  /// - Returns: The flushed heartbeats in the form of `HeartbeatsPayload`.
  @discardableResult
  public func flush() -> HeartbeatsPayload {
    let resetTransform = { (heartbeatsBundle: HeartbeatsBundle?) -> HeartbeatsBundle? in
      guard let oldHeartbeatsBundle = heartbeatsBundle else {
        return nil // Storage was empty.
      }
      // The new value that's stored will use the old's cache to prevent the
      // logging of duplicates after flushing.
      return HeartbeatsBundle(
        capacity: self.heartbeatsStorageCapacity,
        cache: oldHeartbeatsBundle.lastAddedHeartbeatDates
      )
    }

    do {
      // Synchronously gets and returns the stored heartbeats, resetting storage
      // using the given transform.
      let heartbeatsBundle = try storage.getAndSet(using: resetTransform)
      // If no heartbeats bundle was stored, return an empty payload.
      return heartbeatsBundle?.makeHeartbeatsPayload() ?? HeartbeatsPayload.emptyPayload
    } catch {
      // If the operation throws, assume no heartbeat(s) were retrieved or set.
      return HeartbeatsPayload.emptyPayload
    }
  }

  /// Synchronously flushes the heartbeat for today.
  ///
  /// If no heartbeat was logged today, the returned payload is empty.
  ///
  /// - Note: This API is thread-safe.
  /// - Returns: A heartbeats payload for the flushed heartbeat.
  @discardableResult
  public func flushHeartbeatFromToday() -> HeartbeatsPayload {
    let todaysDate = dateProvider()
    var todaysHeartbeat: Heartbeat?

    storage.readAndWriteSync { heartbeatsBundle in
      guard var heartbeatsBundle = heartbeatsBundle else {
        return nil // Storage was empty.
      }

      todaysHeartbeat = heartbeatsBundle.removeHeartbeat(from: todaysDate)

      return heartbeatsBundle
    }

    // Note that `todaysHeartbeat` is updated in the above read/write block.
    if todaysHeartbeat != nil {
      return todaysHeartbeat!.makeHeartbeatsPayload()
    } else {
      return HeartbeatsPayload.emptyPayload
    }
  }
}
