//
//  CustomOpenAIService.swift
//  Easydict
//
//  Created by phlpsong on 2024/2/16.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - CustomOpenAIService

@objc(EZCustomOpenAIService)
class CustomOpenAIService: BaseOpenAIService {
    // MARK: Public

    public override func name() -> String {
        let serviceName = Defaults[super.nameKey]
        return serviceName.isEmpty ? NSLocalizedString("custom_openai", comment: "") : serviceName
    }

    public override func serviceType() -> ServiceType {
        .customOpenAI
    }

    // MARK: Internal

    override var supportsStreamingToggle: Bool { true }

    override var supportsExtraBody: Bool { true }

    override var supportsReasoningEffort: Bool { true }

    override var usesFreeformReasoningEffort: Bool { true }

    /// Free-form value for the OpenAI-compatible `reasoning_effort` field. The
    /// provider decides which strings it accepts, so the value is sent verbatim;
    /// an empty value omits the field.
    override var reasoningEffort: String? {
        let effort = configuredReasoningEffortText
        return effort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : effort
    }

    override func serviceTypeWithUniqueIdentifier() -> String {
        guard !uuid.isEmpty else {
            return ServiceType.customOpenAI.rawValue
        }
        return "\(ServiceType.customOpenAI.rawValue)#\(uuid)"
    }

    override func isDuplicatable() -> Bool {
        true
    }

    override func isDeletable(_ type: EZWindowType) -> Bool {
        !uuid.isEmpty
    }

    override func configurationListItems() -> Any {
        StreamConfigurationView(
            service: self,
            showCustomNameSection: true,
            showStreamingToggle: true
        )
    }
}
