//
//  AppPathManager+Preparation.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

extension AppPathManager {
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
}
