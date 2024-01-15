//
//  ConfigurableService.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/14.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import SwiftUI

protocol ConfigurableService {
    associatedtype T: View

    @ViewBuilder
    func configurationListItems() -> T
}

@available(macOS 13.0, *)
extension ConfigurableService {
    func configurationView() -> some View {
        Form {
            configurationListItems()
        }
        .formStyle(.grouped)
    }
}
