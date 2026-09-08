//
//  CodexConfigurationMigration.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Foundation

/// Finds legacy Codex instances from a raw persistent-domain snapshot taken before
/// default initialization. It never constructs services or reads default getters;
/// callers persist only missing modes, so migration can safely run on every launch.
enum CodexConfigurationMigration {
    // MARK: Internal

    static func legacyUUIDs(in snapshot: [String: Any]) -> Set<String> {
        var identifiers = Set<String>()
        for (key, value) in snapshot {
            if key.hasPrefix("kAllServiceTypesKey-"), let types = value as? [String] {
                for type in types {
                    if type == "CodexCLI" {
                        identifiers.insert("")
                    } else if type.hasPrefix("CodexCLI#") {
                        identifiers.insert(String(type.dropFirst("CodexCLI#".count)))
                    }
                }
            }
            let infoPrefix = "kServiceInfoStorageKey-CodexCLI-"
            if key.hasPrefix(infoPrefix), value is Data {
                let suffix = String(key.dropFirst(infoPrefix.count))
                if let separator = suffix.lastIndex(of: "-") {
                    identifiers.insert(String(suffix[..<separator]))
                } else {
                    identifiers.insert("")
                }
            }
            for configuration in legacyKeys {
                let prefix = "EZCodexCLI" + configuration.rawValue.capitalizeFirstLetter()
                if key == prefix + "Key" {
                    identifiers.insert("")
                } else if key.hasPrefix(prefix + "_"), key.hasSuffix("_Key") {
                    identifiers.insert(String(key.dropFirst(prefix.count + 1).dropLast(4)))
                }
            }
        }
        if let records = snapshot["kQueryServiceRecordKey"] as? [String: [String: Any]],
           let codex = records["CodexCLI"],
           (codex["queryCount"] as? NSNumber)?.intValue ?? 0 > 0 {
            identifiers.insert("")
        }
        return identifiers.filter { snapshot[CodexAccessMode.key(uuid: $0).name] == nil }
    }

    // MARK: Private

    private static let legacyKeys: [ServiceConfigurationKey] = [
        .serviceUsageStatus, .translation, .dictionary, .sentence, .supportedModels,
        .validModels, .model, .apiKey, .endpoint, .name, .enableCustomPrompt,
        .systemPrompt, .userPrompt, .thinkTag, .temperature, .enableStreaming, .reasoningEffort,
    ]
}
