//
//  URL+IsValid.swift
//  Easydict
//
//  Created by tisfeng on 2024/3/24.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

extension URL {
    var isValid: Bool {
        scheme != nil && host != nil
    }
}
