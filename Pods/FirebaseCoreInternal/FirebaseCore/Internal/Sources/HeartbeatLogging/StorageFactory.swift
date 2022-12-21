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

private enum Constants {
  /// The name of the file system directory where heartbeat data is stored.
  static let heartbeatFileStorageDirectoryPath = "google-heartbeat-storage"
  /// The name of the user defaults suite where heartbeat data is stored.
  static let heartbeatUserDefaultsSuiteName = "com.google.heartbeat.storage"
}

/// A factory type for `Storage`.
protocol StorageFactory {
  static func makeStorage(id: String) -> Storage
}

// MARK: - FileStorage + StorageFactory

extension FileStorage: StorageFactory {
  static func makeStorage(id: String) -> Storage {
    let rootDirectory = FileManager.default.applicationSupportDirectory
    let heartbeatDirectoryPath = Constants.heartbeatFileStorageDirectoryPath

    // Sanitize the `id` so the heartbeat file name does not include a ":".
    let sanitizedID = id.replacingOccurrences(of: ":", with: "_")
    let heartbeatFilePath = "heartbeats-\(sanitizedID)"

    let storageURL = rootDirectory
      .appendingPathComponent(heartbeatDirectoryPath, isDirectory: true)
      .appendingPathComponent(heartbeatFilePath, isDirectory: false)

    return FileStorage(url: storageURL)
  }
}

extension FileManager {
  var applicationSupportDirectory: URL {
    urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
  }
}

// MARK: - UserDefaultsStorage + StorageFactory

extension UserDefaultsStorage: StorageFactory {
  static func makeStorage(id: String) -> Storage {
    let suiteName = Constants.heartbeatUserDefaultsSuiteName
    // It's safe to force unwrap the below defaults instance because the
    // initializer only returns `nil` when the bundle id or `globalDomain`
    // is passed in as the `suiteName`.
    let defaults = UserDefaults(suiteName: suiteName)!
    let key = "heartbeats-\(id)"
    return UserDefaultsStorage(defaults: defaults, key: key)
  }
}
