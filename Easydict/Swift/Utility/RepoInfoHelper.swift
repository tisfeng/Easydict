//
//  RepoInfoHelper.swift
//  Easydict
//
//  Created by Sharker on 2024/5/29.
//  Copyright © 2024 izual. All rights reserved.
//

import Alamofire
import Foundation

// MARK: - RepoInfoResponse

struct RepoInfoResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case assetsUrl = "assets_url"
        case createdAt = "created_at"
        case htmlUrl = "html_url"
        case mentionsCount = "mentions_count"
        case nodeId = "node_id"
        case publishedAt = "published_at"
        case tagName = "tag_name"
        case tarballUrl = "tarball_url"
        case targetCommitish = "target_commitish"
        case uploadUrl = "upload_url"
        case zipballUrl = "zipball_url"
    }

    var assets = [RepoInfoResponseAssets]()
    var assetsUrl: String?
    var author: RepoInfoResponseAuthor?
    var body: String?
    var createdAt: String?
    var draft: Bool = false
    var htmlUrl: String?
    var id: Int = 0
    var mentionsCount: Int = 0
    var name: String?
    var nodeId: String?
    var prerelease: Bool = false
    var publishedAt: String?
    var reactions: RepoInfoResponseReactions?
    var tagName: String?
    var tarballUrl: String?
    var targetCommitish: String?
    var uploadUrl: String?
    var url: String?
    var zipballUrl: String?
}

// MARK: - RepoInfoResponseAssets

struct RepoInfoResponseAssets: Codable {
    enum CodingKeys: String, CodingKey {
        case browserDownloadUrl = "browser_download_url"
        case contentType = "content_type"
        case createdAt = "created_at"
        case nodeId = "node_id"
        case updatedAt = "updated_at"
        case downloadCount = "download_count"
    }

    var browserDownloadUrl: String?
    var contentType: String?
    var createdAt: String?
    var downloadCount: Int = 0
    var id: Int = 0
    var label: String?
    var name: String?
    var nodeId: String?
    var size: Int = 0
    var state: String?
    var updatedAt: String?
    var uploader: RepoInfoResponseAssetsUploader?
    var url: String?
}

// MARK: - RepoInfoResponseAssetsUploader

struct RepoInfoResponseAssetsUploader: Codable {
    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case eventsUrl = "events_url"
        case followersUrl = "followers_url"
        case followingUrl = "following_url"
        case gistsUrl = "gists_url"
        case gravatarId = "gravatar_id"
        case htmlUrl = "html_url"
        case nodeId = "node_id"
        case organizationsUrl = "organizations_url"
        case receivedEventsUrl = "received_events_url"
        case reposUrl = "repos_url"
        case siteAdmin = "site_admin"
        case starredUrl = "starred_url"
        case subscriptionsUrl = "subscriptions_url"
    }

    var avatarUrl: String?
    var eventsUrl: String?
    var followersUrl: String?
    var followingUrl: String?
    var gistsUrl: String?
    var gravatarId: String?
    var htmlUrl: String?
    var id: Int = 0
    var login: String?
    var nodeId: String?
    var organizationsUrl: String?
    var receivedEventsUrl: String?
    var reposUrl: String?
    var siteAdmin: Bool = false
    var starredUrl: String?
    var subscriptionsUrl: String?
    var type: String?
    var url: String?
}

// MARK: - RepoInfoResponseReactions

struct RepoInfoResponseReactions: Codable {
    enum CodingKeys: String, CodingKey {
        case reactionsAdd = "+1"
        case reactionsSub = "-1"
        case totalCount = "total_count"
    }

    var reactionsSub: Int = 0
    var reactionsAdd: Int = 0
    var confused: Int = 0
    var eyes: Int = 0
    var heart: Int = 0
    var hooray: Int = 0
    var laugh: Int = 0
    var rocket: Int = 0
    var totalCount: Int = 0
    var url: String?
}

// MARK: - RepoInfoResponseAuthor

struct RepoInfoResponseAuthor: Codable {
    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case eventsUrl = "events_url"
        case followersUrl = "followers_url"
        case followingUrl = "following_url"
        case gistsUrl = "gists_url"
        case gravatarId = "gravatar_id"
        case htmlUrl = "html_url"
        case nodeId = "node_id"
        case organizationsUrl = "organizations_url"
        case receivedEventsUrl = "received_events_url"
        case reposUrl = "repos_url"
        case siteAdmin = "site_admin"
        case starredUrl = "starred_url"
        case subscriptionsUrl = "subscriptions_url"
    }

    var avatarUrl: String?
    var eventsUrl: String?
    var followersUrl: String?
    var followingUrl: String?
    var gistsUrl: String?
    var gravatarId: String?
    var htmlUrl: String?
    var id: Int = 0
    var login: String?
    var nodeId: String?
    var organizationsUrl: String?
    var receivedEventsUrl: String?
    var reposUrl: String?
    var siteAdmin: Bool = false
    var starredUrl: String?
    var subscriptionsUrl: String?
    var type: String?
    var url: String?
}

// MARK: - RepoInfoHelper

class RepoInfoHelper {
    // MARK: Lifecycle

    private init() {
        //
    }

    // MARK: Public

    public func fetchLatestVersion(repoPath: String, completion: @escaping (String) -> ()) {
        fetchRepoInfo(repoPath: repoPath) { response in
            switch response {
            case let .success(resp):
                completion(resp.tagName ?? "")
            case let .failure(err):
                print(err)
            }
        }
    }

    // MARK: Internal

    static let shared = RepoInfoHelper()

    // MARK: Private

    private func fetchRepoInfo(repoPath: String, completion: @escaping (Result<RepoInfoResponse, Error>) -> ()) {
        let url = "https://api.github.com/repos/\(repoPath)/releases/latest"
        AF.request(url).responseDecodable(of: RepoInfoResponse.self) { response in
            switch response.result {
            case let .success(res):
                completion(.success(res))
            case let .failure(err):
                completion(.failure(err))
            }
        }
    }
}
