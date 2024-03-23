//
//  EZLocalizedBundle.swift
//  Easydict
//
//  Created by choykarl on 2024/3/23.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

@objc(EZLocalizedBundle)
class LocalizedBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        I18nHelper.shared.localizedBundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
