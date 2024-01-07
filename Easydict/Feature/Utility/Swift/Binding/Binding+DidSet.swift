//
//  Binding+DidSet.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

// Ref https://stackoverflow.com/a/62871938
// Toggle onChange not trigger issue
extension Binding {
    func didSet(execute: @escaping (Value) -> Void) -> Binding {
        Binding(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                execute($0)
            }
        )
    }
}
