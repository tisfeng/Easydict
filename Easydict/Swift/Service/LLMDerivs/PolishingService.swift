//
//  PolishingService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation

@objc(EZPolishingService)
class PolishingService: LLMDerivService {
    public override func name() -> String {
        NSLocalizedString("polishing_service", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .polishing
    }
}
