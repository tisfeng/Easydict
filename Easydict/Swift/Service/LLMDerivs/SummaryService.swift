//
//  SummaryService.swift
//  Easydict
//
//  Created by Jerry on 2024-07-11.
//  Copyright © 2024 izual. All rights reserved.
//

import Foundation
import OpenAI

@objc(EZSummaryService)
class SummaryService: LLMDerivService {
    public override func name() -> String {
        NSLocalizedString("summary_service", comment: "")
    }

    public override func serviceType() -> ServiceType {
        .summary
    }
}
