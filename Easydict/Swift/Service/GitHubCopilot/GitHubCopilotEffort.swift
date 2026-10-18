//
//  GitHubCopilotEffort.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Foundation

/// Localizes known labels without restricting the levels supplied by the CLI catalog.
enum GitHubCopilotEffort {
    static func title(for value: String) -> String {
        switch value {
        case "": String(localized: "service.github_copilot.effort.default")
        case "none": String(localized: "service.github_copilot.effort.none")
        case "minimal": String(localized: "service.github_copilot.effort.minimal")
        case "low": String(localized: "service.github_copilot.effort.low")
        case "medium": String(localized: "service.github_copilot.effort.medium")
        case "high": String(localized: "service.github_copilot.effort.high")
        case "xhigh": String(localized: "service.github_copilot.effort.xhigh")
        case "max": String(localized: "service.github_copilot.effort.max")
        default: value
        }
    }
}
