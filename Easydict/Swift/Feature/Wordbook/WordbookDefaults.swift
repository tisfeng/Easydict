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
}
