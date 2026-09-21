//
//  AppPathManager.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

/// Provides the app-scoped filesystem locations used by Easydict.
///
/// Path lookup is side-effect free. Call `ensureDirectoryExists(at:attributes:)`
/// explicitly before writing to a directory.
@objcMembers
final class AppPathManager: NSObject {
    // MARK: Lifecycle

    @nonobjc
    init(
        bundleIdentifier: String,
        applicationSupportBaseURL: URL,
        cachesBaseURL: URL
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.applicationSupportBaseURL = applicationSupportBaseURL
        self.cachesBaseURL = cachesBaseURL
        super.init()
    }

    // MARK: Internal

    static let current = AppPathManager(
        bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.izual.Easydict",
        applicationSupportBaseURL: FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].resolvingSymlinksInPath(),
        cachesBaseURL: FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        )[0]
    )

    let bundleIdentifier: String

    /// The bundle-scoped root in `Application Support`.
    var appSupportDirectory: URL {
        applicationSupportBaseURL.appendingPathComponent(bundleIdentifier, isDirectory: true)
    }

    /// The bundle-scoped root in `Caches`.
    var cachesDirectory: URL {
        cachesBaseURL.appendingPathComponent(bundleIdentifier, isDirectory: true)
    }

    /// Creates a directory and any missing ancestors.
    @nonobjc
    func ensureDirectoryExists(
        at directoryURL: URL,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: attributes
        )
    }

    // MARK: Private

    private let applicationSupportBaseURL: URL
    private let cachesBaseURL: URL
}
