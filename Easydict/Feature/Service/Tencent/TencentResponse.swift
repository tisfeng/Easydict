//
//  TencentResponse.swift
//  Easydict
//
//  Created by Jerry on 2023-11-25.
//  Copyright © 2023 izual. All rights reserved.
//

import Foundation

struct TencentResponse: Codable {
    struct Response: Codable {
        var RequestId: String
        var Source: String
        var Target: String
        var TargetText: String
    }

    var Response: Response
}
