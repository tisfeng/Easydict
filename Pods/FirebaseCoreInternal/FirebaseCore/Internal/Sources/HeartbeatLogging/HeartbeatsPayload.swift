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

#if SWIFT_PACKAGE
  import GoogleUtilities_NSData
#else
  import GoogleUtilities
#endif // SWIFT_PACKAGE

/// A type that provides a string representation for use in an HTTP header.
public protocol HTTPHeaderRepresentable {
  func headerValue() -> String
}

/// A value type representing a payload of heartbeat data intended for sending in network requests.
///
/// This type's structure is optimized for type-safe encoding into a HTTP payload format.
/// The current encoding format for the payload's current version is:
///
///     {
///       "version": 2,
///       "heartbeats": [
///         {
///           "agent": "dummy_agent_1",
///           "dates": ["2021-11-01", "2021-11-02"]
///         },
///         {
///           "agent": "dummy_agent_2",
///           "dates": ["2021-11-03"]
///         }
///       ]
///     }
///
public struct HeartbeatsPayload: Codable {
  /// The version of the payload. See go/firebase-apple-heartbeats for details regarding current version.
  static let version: Int = 2

  /// A payload component composed of a user agent and array of dates (heartbeats).
  struct UserAgentPayload: Codable {
    /// An anonymous agent string.
    let agent: String
    /// An array of dates where each date represents a "heartbeat".
    let dates: [Date]
  }

  /// An array of user agent payloads.
  let userAgentPayloads: [UserAgentPayload]
  /// The version of the payload structure.
  let version: Int

  /// Alternative keys for properties so encoding follows platform-wide payload structure.
  enum CodingKeys: String, CodingKey {
    case userAgentPayloads = "heartbeats"
    case version
  }

  /// Designated initializer.
  /// - Parameters:
  ///   - userAgentPayloads: An array of payloads containing heartbeat data corresponding to a
  ///   given user agent.
  ///   - version: A  version of the payload. Defaults to the static default.
  init(userAgentPayloads: [UserAgentPayload] = [], version: Int = version) {
    self.userAgentPayloads = userAgentPayloads
    self.version = version
  }

  /// A Boolean value indicating whether the payload is empty.
  public var isEmpty: Bool {
    userAgentPayloads.isEmpty
  }
}

// MARK: - HTTPHeaderRepresentable

extension HeartbeatsPayload: HTTPHeaderRepresentable {
  /// Returns a processed payload string intended for use in a HTTP header.
  /// - Returns: A string value from the heartbeats payload.
  public func headerValue() -> String {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(Self.dateFormatter)

    guard let data = try? encoder.encode(self) else {
      // If encoding fails, fall back to encoding with an empty payload.
      return Self.emptyPayload.headerValue()
    }

    do {
      let gzippedData = try data.zipped()
      return gzippedData.base64URLEncodedString()
    } catch {
      // If gzipping fails, fall back to encoding with base64URL.
      return data.base64URLEncodedString()
    }
  }
}

// MARK: - Static Defaults

extension HeartbeatsPayload {
  /// Convenience instance that represents an empty payload.
  static let emptyPayload = HeartbeatsPayload()

  /// A default date formatter that uses `YYYY-MM-dd` format.
  public static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "YYYY-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
}

// MARK: - Equatable

extension HeartbeatsPayload: Equatable {}
extension HeartbeatsPayload.UserAgentPayload: Equatable {}

// MARK: - Data

public extension Data {
  /// Returns a Base-64 URL-safe encoded string.
  ///
  /// - parameter options: The options to use for the encoding. Default value is `[]`.
  /// - returns: The Base-64 URL-safe encoded string.
  func base64URLEncodedString(options: Data.Base64EncodingOptions = []) -> String {
    base64EncodedString()
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "=", with: "")
  }

  /// Initialize a `Data` from a Base-64 URL encoded String using the given options.
  ///
  /// Returns nil when the input is not recognized as valid Base-64.
  /// - parameter base64URLString: The string to parse.
  /// - parameter options: Encoding options. Default value is `[]`.
  init?(base64URLEncoded base64URLString: String, options: Data.Base64DecodingOptions = []) {
    var base64Encoded = base64URLString
      .replacingOccurrences(of: "_", with: "/")
      .replacingOccurrences(of: "-", with: "+")

    // Pad the string with "=" signs until the string's length is a multiple of 4.
    while !base64Encoded.count.isMultiple(of: 4) {
      base64Encoded.append("=")
    }

    self.init(base64Encoded: base64Encoded, options: options)
  }

  /// Returns the compressed data.
  /// - Returns: The compressed data.
  /// - Throws: An error if compression failed.
  func zipped() throws -> Data {
    try NSData.gul_data(byGzippingData: self)
  }

  /// Returns the uncompressed data.
  /// - Returns: The decompressed data.
  /// - Throws: An error if decompression failed.
  func unzipped() throws -> Data {
    try NSData.gul_data(byInflatingGzippedData: self)
  }
}
