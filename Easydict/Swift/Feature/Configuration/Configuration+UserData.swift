//
//  Configuration+UserData.swift
//  Easydict
//
//  Created by ljk on 2024/1/17.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension MyConfiguration {
    func resetUserDefaultsData() {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
    }
}
