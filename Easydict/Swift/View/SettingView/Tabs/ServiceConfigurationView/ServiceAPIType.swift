//
//  ServiceAPIType.swift
//  Easydict
//
//  Created by karl on 2024/7/25.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

enum ServiceAPIType: String, CaseIterable, Defaults.Serializable, EnumLocalizedStringConvertible {
    case web = "Web API"
    case secretKey = "Secret Key API"

    // MARK: Internal

    var title: LocalizedStringKey {
        LocalizedStringKey(rawValue)
    }
}
