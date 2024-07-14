//
//  File.swift
//  Easydict
//
//  Created by tisfeng on 2024/6/5.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

// MARK: - EnumLocalizedStringConvertible

protocol EnumLocalizedStringConvertible {
    var title: LocalizedStringKey { get }
}

// MARK: - ServiceUsageStatus

enum ServiceUsageStatus: String, CaseIterable {
    case `default` = "0"
    case alwaysOff = "1"
    case alwaysOn = "2"
}

// MARK: EnumLocalizedStringConvertible

extension ServiceUsageStatus: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        switch self {
        case .default:
            "service.configuration.openai.usage_status_default.title"
        case .alwaysOff:
            "service.configuration.openai.usage_status_always_off.title"
        case .alwaysOn:
            "service.configuration.openai.usage_status_always_on.title"
        }
    }
}

// MARK: - String + EnumLocalizedStringConvertible

extension String: EnumLocalizedStringConvertible {
    var title: LocalizedStringKey {
        LocalizedStringKey(self)
    }
}

// MARK: - ServiceUsageStatus + Defaults.Serializable

extension ServiceUsageStatus: Defaults.Serializable {}
