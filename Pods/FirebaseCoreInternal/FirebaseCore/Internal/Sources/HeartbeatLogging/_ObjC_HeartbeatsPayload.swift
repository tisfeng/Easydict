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

/// A model object representing a payload of heartbeat data intended for sending in network requests.
@objc(FIRHeartbeatsPayload)
public class _ObjC_HeartbeatsPayload: NSObject, HTTPHeaderRepresentable {
  /// The underlying Swift structure.
  private let heartbeatsPayload: HeartbeatsPayload

  /// Designated initializer.
  /// - Parameter heartbeatsPayload: A native-Swift heartbeats payload.
  public init(_ heartbeatsPayload: HeartbeatsPayload) {
    self.heartbeatsPayload = heartbeatsPayload
  }

  /// Returns a processed payload string intended for use in a HTTP header.
  /// - Returns: A string value from the heartbeats payload.
  @objc public func headerValue() -> String {
    heartbeatsPayload.headerValue()
  }

  /// A Boolean value indicating whether the payload is empty.
  @objc public var isEmpty: Bool {
    heartbeatsPayload.isEmpty
  }
}
