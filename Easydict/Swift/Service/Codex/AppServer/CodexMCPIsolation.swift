//
//  CodexMCPIsolation.swift
//  Easydict
//
//  Created by tisfeng on 2026/11/20.
//

import Foundation

/// The shared OCR/translation contract: no enabled MCP servers and a verified
/// read-only ephemeral thread before submitting any source text or image.
struct CodexMCPIsolation {
    /// Reads the effective configuration, treating omitted `enabled` as true.
    /// A missing or malformed server table cannot establish isolation.
    func enabledServers(in response: [String: Any]) -> [String]? {
        guard let configuration = response["config"] as? [String: Any],
              let servers = configuration["mcp_servers"] as? [String: Any] else { return nil }
        var enabled: [String] = []
        for (name, value) in servers {
            guard let server = value as? [String: Any] else { return nil }
            if let flag = server["enabled"] {
                guard let flag = flag as? Bool else { return nil }
                if !flag { continue }
            }
            enabled.append(name)
        }
        return enabled.sorted()
    }

    /// Empty TOML tables merge rather than clear inherited servers. Override
    /// each enabled value, quoting literal table keys instead of dotted paths.
    func disablingArguments(for serverNames: [String]) throws -> [String] {
        guard !serverNames.isEmpty else { return [] }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        let entries = try serverNames.sorted().map { name in
            guard let key = String(data: try encoder.encode(name), encoding: .utf8) else {
                preconditionFailure("JSONEncoder returned non-UTF-8 data")
            }
            return "\(key)={enabled=false}"
        }
        return ["-c", "mcp_servers={\(entries.joined(separator: ","))}"]
    }

    func acceptsThread(_ response: [String: Any]) -> Bool {
        guard let thread = response["thread"] as? [String: Any],
              let identifier = thread["id"] as? String, !identifier.isEmpty,
              thread["ephemeral"] as? Bool == true,
              let sandbox = response["sandbox"] as? [String: Any],
              sandbox["type"] as? String == "readOnly",
              response["approvalPolicy"] as? String == "never" else { return false }
        return sandbox["networkAccess"] as? Bool == false
    }
}
