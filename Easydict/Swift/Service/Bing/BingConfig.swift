//
//  BingConfig.swift
//  Easydict
//
//  Created by tisfeng on 2025/11/28.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

private let kBingConfigKey = "kBingConfigKey"

// MARK: - BingConfig

class BingConfig: NSObject, Codable {
    // MARK: Lifecycle

    override init() {
        super.init()
    }

    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.IG = try container.decodeIfPresent(String.self, forKey: .IG)
        self.IID = try container.decodeIfPresent(String.self, forKey: .IID)
        self.key = try container.decodeIfPresent(String.self, forKey: .key)
        self.token = try container.decodeIfPresent(String.self, forKey: .token)
        self.expirationInterval = try container.decodeIfPresent(String.self, forKey: .expirationInterval)
        self.host = try container.decodeIfPresent(String.self, forKey: .host)
    }

    // MARK: Internal

    // MARK: - Constants

    static let defaultHost = "www.bing.com"
    static let chinaHost = "cn.bing.com"

    var IG: String?
    var IID: String?
    var key: String?
    var token: String?
    var expirationInterval: String?
    var host: String?

    var cookie: String {
        UserDefaults.standard.string(forKey: EZBingCookieKey) ?? ""
    }

    var translatorURLString: String {
        "https://\(host ?? BingConfig.chinaHost)/translator"
    }

    var ttranslatev3URLString: String {
        urlString(withPath: "ttranslatev3")
    }

    var tlookupv3URLString: String {
        urlString(withPath: "tlookupv3")
    }

    var tfetttsURLString: String {
        urlString(withPath: "tfettts")
    }

    var dictTranslateURLString: String {
        "https://\(host ?? BingConfig.chinaHost)/api/v7/dictionarywords/search?appid=371E7B2AF0F9B84EC491D731DF90A55719C7D209&mkt=zh-cn&pname=bingdict"
    }

    // MARK: - Methods

    func isBingTokenExpired() -> Bool {
        guard let key else {
            return true
        }

        let tokenStart = Double(key) ?? 0

        // Convert to millisecond
        let now = Date().timeIntervalSince1970 * 1000

        /// expirationInterval is 3600000 ms, 3600000/1000/60 = 60 mins
        /// Default expiration is 60 mins, for better experience, we get a new token after 30 min.
        let tokenUsedTime = now - tokenStart
        let expirationIntervalValue = Double(expirationInterval ?? "3600000") ?? 3600000
        let isExpired = tokenUsedTime > expirationIntervalValue / 2

        logInfo("is Bing token expired: \(isExpired ? "YES" : "NO")")

        return isExpired
    }

    func resetToken() {
        IID = nil
        IG = nil
        key = nil
        expirationInterval = nil
        token = nil
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(IG, forKey: .IG)
        try container.encodeIfPresent(IID, forKey: .IID)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(token, forKey: .token)
        try container.encodeIfPresent(expirationInterval, forKey: .expirationInterval)
        try container.encodeIfPresent(host, forKey: .host)
    }

    // MARK: Private

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case IG
        case IID
        case key
        case token
        case expirationInterval
        case host
    }

    // MARK: - Private Methods

    private func urlString(withPath path: String) -> String {
        "https://\(host ?? BingConfig.chinaHost)/\(path)?isVertical=1&IG=\(IG ?? "")&IID=\(IID ?? "")"
    }
}

// MARK: - BingConfig + Persistence

extension BingConfig {
    // MARK: - Save & Load

    static func loadFromUserDefaults() -> BingConfig {
        guard let data = UserDefaults.standard.data(forKey: kBingConfigKey),
              let config = try? JSONDecoder().decode(BingConfig.self, from: data)
        else {
            return BingConfig()
        }
        return config
    }

    func saveToUserDefaults() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: kBingConfigKey)
    }
}
