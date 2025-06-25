//
//  Float+ToCGFloat.swift
//  Easydict
//
//  Created by tisfeng on 2025/6/25.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

extension Float {
    var cgFloat: CGFloat { CGFloat(self) }
    var double: Double { Double(self) }
}

extension CGFloat {
    var float: Float { Float(self) }
    var double: Double { Double(self) }
}
