//
//  EasydictRepo.swift
//  Easydict
//
//  Created by tisfeng on 2026/10/14.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - EasydictRepo

/// GitHub repository info of Easydict.
enum EasydictRepo {
    /// Repository full name, eg. tisfeng/Easydict
    static let name = "tisfeng/Easydict"

    static let url = URL(string: "https://github.com/\(name)")!
    static let releasesURL = url.appending(path: "releases")
    static let issuesURL = url.appending(path: "issues")
}
