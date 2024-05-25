//
//  ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - ConfigurableService

/// A service can provide configuration view in setting
protocol ConfigurableService {
    // swiftlint:disable:next type_name
    associatedtype T: View

    /// Items in Configuration Form. Use ServiceStringConfigurationSection or other customize view.
    @ViewBuilder
    func configurationListItems() -> T
}

extension ConfigurableService {
    func configurationView() -> some View {
        Form {
            configurationListItems()
        }
        .formStyle(.grouped)
    }
}
