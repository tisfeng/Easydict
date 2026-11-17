//
//  DeepLWebAppVersionProvider.swift
//  Easydict
//
//  Created by tisfeng on 2026/9/29.
//  Copyright © 2026 izual. All rights reserved.
//

import Alamofire
import Defaults
import Foundation

private let kDeepLAppStoreLookupURL = URL(
    string: "https://itunes.apple.com/lookup?id=1552407475&country=us"
)!
private let kDeepLWebAppVersionFallback = "26.52"
private let kDeepLWebAppVersionCacheLifetime: TimeInterval = 24 * 60 * 60
private let kDeepLWebAppVersionRetryDelay: TimeInterval = 15 * 60
private let kDeepLWebAppVersionLookupTimeout: TimeInterval = 3

// MARK: - DeepLWebAppVersionProvider

/// Resolves and caches the current DeepL iOS App Store version used by the web client request.
actor DeepLWebAppVersionProvider {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = DeepLWebAppVersionProvider()

    /// Returns a recently fetched version, refreshing it when the cache has expired.
    func currentVersion() async -> String {
        var state = loadState()
        let now = Date()

        if let version = validCachedVersion(in: state),
           let fetchedAt = state.fetchedAt,
           isWithin(fetchedAt, lifetime: kDeepLWebAppVersionCacheLifetime, now: now) {
            return version
        }

        if let lookupTask {
            return await resolve(lookupTask, using: state)
        }

        if let lastAttemptAt = state.lastAttemptAt,
           isWithin(lastAttemptAt, lifetime: kDeepLWebAppVersionRetryDelay, now: now) {
            return validCachedVersion(in: state) ?? kDeepLWebAppVersionFallback
        }

        state.lastAttemptAt = now
        saveState(state)

        let task = Task { await Self.fetchLatestVersion() }
        lookupTask = task
        return await resolve(task, using: state)
    }

    // MARK: Private

    private struct CachedState: Codable {
        var version: String?
        var fetchedAt: Date?
        var lastAttemptAt: Date?
    }

    private var cachedState: CachedState?
    private var lookupTask: Task<String?, Never>?

    private static func fetchLatestVersion() async -> String? {
        let request = URLRequest(
            url: kDeepLAppStoreLookupURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: kDeepLWebAppVersionLookupTimeout
        )

        do {
            let data = try await AF.request(request)
                .validate(statusCode: 200 ..< 300)
                .serializingData()
                .value
            return DeepLAppStoreVersionParser.version(from: data)
        } catch {
            return nil
        }
    }

    private func resolve(_ task: Task<String?, Never>, using state: CachedState) async -> String {
        let fetchedVersion = await task.value
        lookupTask = nil

        guard let fetchedVersion else {
            logError("Failed to refresh DeepL App Store version; using cached or fallback version")
            return validCachedVersion(in: state) ?? kDeepLWebAppVersionFallback
        }

        let now = Date()
        saveState(CachedState(
            version: fetchedVersion,
            fetchedAt: now,
            lastAttemptAt: now
        ))
        return fetchedVersion
    }

    private func loadState() -> CachedState {
        if let cachedState {
            return cachedState
        }

        guard let data = Defaults[.deepLWebAppVersionCache].data(using: .utf8),
              let state = try? JSONDecoder().decode(CachedState.self, from: data)
        else {
            let emptyState = CachedState(version: nil, fetchedAt: nil, lastAttemptAt: nil)
            cachedState = emptyState
            return emptyState
        }

        cachedState = state
        return state
    }

    private func saveState(_ state: CachedState) {
        cachedState = state
        guard let data = try? JSONEncoder().encode(state) else { return }
        guard let serializedState = String(data: data, encoding: .utf8) else { return }
        Defaults[.deepLWebAppVersionCache] = serializedState
    }

    private func validCachedVersion(in state: CachedState) -> String? {
        guard let version = state.version,
              DeepLAppStoreVersionParser.isValidVersion(version)
        else {
            return nil
        }
        return version
    }

    private func isWithin(_ date: Date, lifetime: TimeInterval, now: Date) -> Bool {
        let age = now.timeIntervalSince(date)
        return age >= 0 && age < lifetime
    }
}

// MARK: - DeepLAppStoreVersionParser

enum DeepLAppStoreVersionParser {
    // MARK: Internal

    static func version(from data: Data) -> String? {
        guard let response = try? JSONDecoder().decode(LookupResponse.self, from: data),
              response.resultCount == 1,
              response.results.count == 1,
              let app = response.results.first,
              app.trackId == 1_552_407_475,
              app.bundleId == "com.linguee.DeepLMobileTranslator",
              app.artistName == "DeepL SE",
              isValidVersion(app.version)
        else {
            return nil
        }

        return app.version
    }

    static func isValidVersion(_ version: String) -> Bool {
        let components = version.split(separator: ".", omittingEmptySubsequences: false)
        return (2 ... 4).contains(components.count) && components.allSatisfy { component in
            !component.isEmpty && component.unicodeScalars.allSatisfy { (48 ... 57).contains($0.value) }
        }
    }

    // MARK: Private

    private struct LookupResponse: Decodable {
        struct App: Decodable {
            let trackId: Int
            let bundleId: String
            let artistName: String
            let version: String
        }

        let resultCount: Int
        let results: [App]
    }
}
