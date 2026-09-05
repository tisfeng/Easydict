//
//  WordbookDefaults.swift
//  Easydict
//
//  Created by liangkaiwen on 2026/7/13.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

extension Defaults.Keys {
    static let wordbookMigrationVersion = Key<Int>(
        "EZConfiguration_kWordbookMigrationVersion",
        default: 0
    )
    static let wordbookSection = Key<String>(
        "wordbook.section",
        default: WordbookSection.wordbook.rawValue
    )
    static let wordbookSort = Key<String>(
        "wordbook.sort",
        default: WordbookSortOrder.newest.rawValue
    )
    static let wordbookHistorySort = Key<String>(
        "wordbook.history_sort",
        default: WordbookHistorySortOrder.newest.rawValue
    )
}
