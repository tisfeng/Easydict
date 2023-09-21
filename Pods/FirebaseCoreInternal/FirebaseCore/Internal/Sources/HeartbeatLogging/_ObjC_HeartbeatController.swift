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
@objc(FIRHeartbeatController)
@objcMembers
public class _ObjC_HeartbeatController: NSObject {
  /// The underlying Swift object.
  private let heartbeatController: HeartbeatController

  /// Public initializer.
  /// - Parameter id: The `id` to associate this controller's heartbeat storage with.
  public init(id: String) {
    heartbeatController = HeartbeatController(id: id)
  }

  /// Asynchronously logs a new heartbeat, if needed.
  ///
  /// - Note: This API is thread-safe.
  /// - Parameter agent: The string agent (i.e. Firebase User Agent) to associate the logged
  /// heartbeat with.
  public func log(_ agent: String) {
    heartbeatController.log(agent)
  }

  /// Synchronously flushes heartbeats from storage into a heartbeats payload.
  ///
  /// - Note: This API is thread-safe.
  /// - Returns: A heartbeats payload for the flushed heartbeat(s).
  public func flush() -> _ObjC_HeartbeatsPayload {
    let heartbeatsPayload = heartbeatController.flush()
    return _ObjC_HeartbeatsPayload(heartbeatsPayload)
  }

  /// Synchronously flushes the heartbeat for today.
  ///
  /// If no heartbeat was logged today, the returned payload is empty.
  ///
  /// - Note: This API is thread-safe.
  /// - Returns: A heartbeats payload for the flushed heartbeat.
  public func flushHeartbeatFromToday() -> _ObjC_HeartbeatsPayload {
    let heartbeatsPayload = heartbeatController.flushHeartbeatFromToday()
    return _ObjC_HeartbeatsPayload(heartbeatsPayload)
  }
}
