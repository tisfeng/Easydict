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

/// A type that reads from and writes to an underlying storage container.
protocol Storage {
  /// Reads and returns the data stored by this storage type.
  /// - Returns: The data read from storage.
  /// - Throws: An error if the read failed.
  func read() throws -> Data

  /// Writes the given data to this storage type.
  /// - Throws: An error if the write failed.
  func write(_ data: Data?) throws
}

/// Error types for `Storage` operations.
enum StorageError: Error {
  case readError
  case writeError
}

// MARK: - FileStorage

/// A object that provides API for reading and writing to a file system resource.
final class FileStorage: Storage {
  /// A  file system URL to the underlying file resource.
  private let url: URL
  /// The file manager used to perform file system operations.
  private let fileManager: FileManager

  /// Designated initializer.
  /// - Parameters:
  ///   - url: A file system URL for the underlying file resource.
  ///   - fileManager: A file manager. Defaults to `default` manager.
  init(url: URL, fileManager: FileManager = .default) {
    self.url = url
    self.fileManager = fileManager
  }

  /// Reads and returns the data from this object's associated file resource.
  ///
  /// - Returns: The data stored on disk.
  /// - Throws: An error if reading the contents of the file resource fails (i.e. file doesn't
  /// exist).
  func read() throws -> Data {
    do {
      return try Data(contentsOf: url)
    } catch {
      throw StorageError.readError
    }
  }

  /// Writes the given data to this object's associated file resource.
  ///
  /// When the given `data` is `nil`, this object's associated file resource is emptied.
  ///
  /// - Parameter data: The `Data?` to write to this object's associated file resource.
  func write(_ data: Data?) throws {
    do {
      try createDirectories(in: url.deletingLastPathComponent())
      if let data = data {
        try data.write(to: url, options: .atomic)
      } else {
        let emptyData = Data()
        try emptyData.write(to: url, options: .atomic)
      }
    } catch {
      throw StorageError.writeError
    }
  }

  /// Creates all directories in the given file system URL.
  ///
  /// If the directory for the given URL already exists, the error is ignored because the directory
  /// has already been created.
  ///
  /// - Parameter url: The URL to create directories in.
  private func createDirectories(in url: URL) throws {
    do {
      try fileManager.createDirectory(
        at: url,
        withIntermediateDirectories: true
      )
    } catch CocoaError.fileWriteFileExists {
      // Directory already exists.
    } catch { throw error }
  }
}

// MARK: - UserDefaultsStorage

/// A object that provides API for reading and writing to a user defaults resource.
final class UserDefaultsStorage: Storage {
  /// The underlying defaults container.
  private let defaults: UserDefaults
  /// The key mapping to the object's associated resource in `defaults`.
  private let key: String

  /// Designated initializer.
  /// - Parameters:
  ///   - defaults: The defaults container.
  ///   - key: The key mapping to the value stored in the defaults container.
  init(defaults: UserDefaults, key: String) {
    self.defaults = defaults
    self.key = key
  }

  /// Reads and returns the data from this object's associated defaults resource.
  ///
  /// - Returns: The data stored on disk.
  /// - Throws: An error if no data has been stored to the defaults container.
  func read() throws -> Data {
    if let data = defaults.data(forKey: key) {
      return data
    } else {
      throw StorageError.readError
    }
  }

  /// Writes the given data to this object's associated defaults.
  ///
  /// When the given `data` is `nil`, the associated default is removed.
  ///
  /// - Parameter data: The `Data?` to write to this object's associated defaults.
  func write(_ data: Data?) throws {
    if let data = data {
      defaults.set(data, forKey: key)
    } else {
      defaults.removeObject(forKey: key)
    }
  }
}
