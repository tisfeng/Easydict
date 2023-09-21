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

#if DEBUG

  import Foundation

  /// A utility class intended to be used only in testing contexts.
  @objc(FIRHeartbeatLoggingTestUtils)
  @objcMembers
  public class HeartbeatLoggingTestUtils: NSObject {
    /// This should mirror the `Constants` enum in the `HeartbeatLogging` module.
    /// See `HeartbeatLogging/Sources/StorageFactory.swift`.
    public enum Constants {
      /// The name of the file system directory where heartbeat data is stored.
      public static let heartbeatFileStorageDirectoryPath = "google-heartbeat-storage"
      /// The name of the user defaults suite where heartbeat data is stored.
      public static let heartbeatUserDefaultsSuiteName = "com.google.heartbeat.storage"
    }

    public static var dateFormatter: DateFormatter {
      HeartbeatsPayload.dateFormatter
    }

    public static var emptyHeartbeatsPayload: _ObjC_HeartbeatsPayload {
      let literalData = """
         {
           "version": 2,
           "heartbeats": []
         }
      """
      .data(using: .utf8)!

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .formatted(HeartbeatsPayload.dateFormatter)

      let heartbeatsPayload = try! decoder.decode(HeartbeatsPayload.self, from: literalData)
      return _ObjC_HeartbeatsPayload(heartbeatsPayload)
    }

    public static var nonEmptyHeartbeatsPayload: _ObjC_HeartbeatsPayload {
      let literalData = """
         {
           "version": 2,
           "heartbeats": [
             {
               "agent": "dummy_agent_1",
               "dates": ["2021-11-01", "2021-11-02"]
             },
             {
               "agent": "dummy_agent_2",
               "dates": ["2021-11-03"]
             }
           ]
         }
      """
      .data(using: .utf8)!

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .formatted(HeartbeatsPayload.dateFormatter)

      let heartbeatsPayload = try! decoder.decode(HeartbeatsPayload.self, from: literalData)
      return _ObjC_HeartbeatsPayload(heartbeatsPayload)
    }

    @objc(assertEncodedPayloadString:isEqualToLiteralString:withError:)
    public static func assertEqualPayloadStrings(_ encoded: String, _ literal: String) throws {
      var encodedData = Data(base64URLEncoded: encoded)!
      if encodedData.count > 0 {
        encodedData = try! encodedData.unzipped()
      }

      let literalData = literal.data(using: .utf8)!

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .formatted(HeartbeatsPayload.dateFormatter)

      let payloadFromEncoded = try? decoder.decode(HeartbeatsPayload.self, from: encodedData)

      let payloadFromLiteral = try? decoder.decode(HeartbeatsPayload.self, from: literalData)

      let encoder = JSONEncoder()
      encoder.dateEncodingStrategy = .formatted(HeartbeatsPayload.dateFormatter)
      encoder.outputFormatting = .prettyPrinted

      let payloadDataFromEncoded = try! encoder.encode(payloadFromEncoded)
      let payloadDataFromLiteral = try! encoder.encode(payloadFromLiteral)

      assert(
        payloadFromEncoded == payloadFromLiteral,
        """
        Mismatched payloads!

        Payload 1:
        \(String(data: payloadDataFromEncoded, encoding: .utf8) ?? "")

        Payload 2:
        \(String(data: payloadDataFromLiteral, encoding: .utf8) ?? "")

        """
      )
    }

    /// Removes all underlying storage containers used by the module.
    /// - Throws: An error if the storage container could not be removed.
    public static func removeUnderlyingHeartbeatStorageContainers() throws {
      #if os(tvOS)
        UserDefaults().removePersistentDomain(forName: Constants.heartbeatUserDefaultsSuiteName)
      #else

        let applicationSupportDirectory = FileManager.default
          .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

        let heartbeatsDirectoryURL = applicationSupportDirectory
          .appendingPathComponent(
            Constants.heartbeatFileStorageDirectoryPath, isDirectory: true
          )
        do {
          try FileManager.default.removeItem(at: heartbeatsDirectoryURL)
        } catch CocoaError.fileNoSuchFile {
          // Do nothing.
        } catch {
          throw error
        }
      #endif // os(tvOS)
    }
  }

#endif // ENABLE_FIREBASE_CORE_INTERNAL_TESTING_UTILS
