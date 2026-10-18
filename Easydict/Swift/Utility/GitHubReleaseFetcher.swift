//
//  GitHubReleaseFetcher.swift
//  Easydict
//
//  Created by Sharker on 2024/5/29.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - GitHubReleaseFetcher

/// Fetches release versions of a GitHub repository.
enum GitHubReleaseFetcher {
    // MARK: Internal

    /// Get the latest release version.
    /// - Parameters:
    ///   - repo: repo name, eg. tisfeng/Easydict
    ///   - includePrerelease: include pre-releases
    /// - Returns: release tag name, eg. 2.7.2, or nil if the request fails.
    static func latestVersion(
        of repo: String = AppConstants.repoName,
        includePrerelease: Bool
    ) async
        -> String? {
        let release = includePrerelease
            ? try? await newestRelease(of: repo)
            : try? await latestStableRelease(of: repo)
        return release?.tagName
    }

    /// Whether `candidate` is a newer version than `current`, eg. 2.10.0 is newer than 2.9.1.
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        current.compare(candidate, options: .numeric) == .orderedAscending
    }

    // MARK: Private

    private static func latestStableRelease(of repo: String) async throws -> GitHubRelease {
        let url = "https://api.github.com/repos/\(repo)/releases/latest"
        return try await AF.request(url).serializingDecodable(GitHubRelease.self).value
    }

    /// The most recent release, including pre-releases.
    private static func newestRelease(of repo: String) async throws -> GitHubRelease? {
        let url = "https://api.github.com/repos/\(repo)/releases?per_page=1"
        return try await AF.request(url).serializingDecodable([GitHubRelease].self).value.first
    }
}

// MARK: - GitHubRelease

/// The subset of a GitHub release response that Easydict uses.
struct GitHubRelease: Decodable {
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
    }

    let tagName: String
}
