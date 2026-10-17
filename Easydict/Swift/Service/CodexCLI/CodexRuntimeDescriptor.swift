//
//  CodexRuntimeDescriptor.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Darwin
import Foundation

// MARK: - CodexRuntimeRelease

/// Pins the binary, translation catalog and execution policy as one release.
enum CodexRuntimeRelease: String, Codable, CaseIterable, Sendable {
    case legacy = "0.134.0"
    case modern = "0.153.4"

    // MARK: Internal

    static var current: Self {
        selected(osMajorVersion: ProcessInfo.processInfo.operatingSystemVersion.majorVersion)
    }

    var defaultModel: String {
        switch self {
        case .legacy: "gpt-5.5"
        case .modern: "gpt-5.6-luna"
        }
    }

    static func selected(osMajorVersion: Int) -> Self {
        osMajorVersion >= 15 ? .modern : .legacy
    }
}

// MARK: - CodexRuntimeArchitecture

enum CodexRuntimeArchitecture: String, Codable, Sendable {
    case appleSilicon = "aarch64"
    case intel = "x86_64"

    // MARK: Internal

    static var current: Self {
        #if arch(arm64)
        return .appleSilicon
        #else
        // An Intel app under Rosetta can still install the native Apple package.
        var arm64: Int32 = 0
        var size = MemoryLayout<Int32>.size
        if sysctlbyname("hw.optional.arm64", &arm64, &size, nil, 0) == 0, arm64 == 1 {
            return .appleSilicon
        }
        return .intel
        #endif
    }
}

// MARK: - CodexRuntimeDescriptor

struct CodexRuntimeDescriptor: Sendable {
    // MARK: Internal

    struct Package: Codable, Sendable {
        let target: String
        let archiveSHA256: String
        let archiveSize: Int64
        let files: [String: String]
        let directories: [String]
        let signatureRequirements: [String: String]
    }

    let release: CodexRuntimeRelease
    let architecture: CodexRuntimeArchitecture
    let package: Package
    let catalogURL: URL

    let downloadURL: URL

    static func load(
        bundle: Bundle = .main,
        release: CodexRuntimeRelease = .current,
        architecture: CodexRuntimeArchitecture = .current
    ) throws
        -> Self {
        guard let resources = bundle.resourceURL else { throw CodexManagedError.componentMissing }
        let root = resources.appendingPathComponent("CodexRuntime")
        let manifest = try JSONDecoder().decode(
            Manifest.self,
            from: Data(contentsOf: root.appendingPathComponent("runtime-manifest.json"))
        )
        guard let version = manifest.versions[release.rawValue],
              let package = version.packages[architecture.rawValue],
              version.minimumOS == (release == .modern ? 15 : 13),
              package.target == "\(architecture.rawValue)-apple-darwin"
        else { throw CodexManagedError.componentMissing }
        return Self(
            release: release,
            architecture: architecture,
            package: package,
            catalogURL: root.appendingPathComponent("\(release.rawValue)/translation-models.json"),
            downloadURL: URL(
                string: "https://github.com/openai/codex/releases/download/rust-v\(release.rawValue)/codex-package-\(package.target).tar.gz"
            )!
        )
    }

    // MARK: Private

    private struct Manifest: Decodable {
        struct Version: Decodable {
            let minimumOS: Int
            let packages: [String: Package]
        }

        let versions: [String: Version]
    }
}

// MARK: - CodexModelCatalog

struct CodexModelCatalog: Decodable {
    struct Model: Decodable {
        struct Reasoning: Decodable {
            let effort: String
        }

        let slug: String
        let supported_reasoning_levels: [Reasoning]
    }

    let models: [Model]

    static func load(at url: URL) throws -> Self {
        do {
            return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        } catch {
            throw CodexManagedError.componentMissing
        }
    }

    /// Accepts a model identifier, never a URL, CLI option or configuration expression.
    static func isValidModelID(_ model: String) -> Bool {
        !model.isEmpty && model.utf8.count <= 128
            && model.range(of: "^[A-Za-z0-9][A-Za-z0-9._-]*$", options: .regularExpression) != nil
    }

    /// An explicit text-only profile for the pinned modern runtime. Unknown models
    /// inherit no other model's instructions, reasoning defaults or optional capabilities.
    static func customModelData(model: String, effort: String? = nil) throws -> Data {
        guard isValidModelID(model) else { throw CodexManagedError.invalidModel }
        try CodexReasoningEffort.validateCustomOverride(effort)
        // This catalog admits the requested override to the transport. A successful
        // request, not this local declaration, validates the model/effort combination.
        let reasoning = effort.map { [["effort": $0, "description": $0]] } ?? []
        let profile: [String: Any] = [
            "slug": model,
            "display_name": model,
            "supported_reasoning_levels": reasoning,
            "shell_type": "disabled",
            "visibility": "list",
            "supported_in_api": true,
            "priority": 0,
            "support_verbosity": false,
            "truncation_policy": ["mode": "tokens", "limit": 10000],
            "experimental_supported_tools": [],
            "input_modalities": ["text"],
            "tool_mode": "direct",
            "use_responses_lite": false,
            "supports_reasoning_summary_parameter": false,
            "default_reasoning_summary": "none",
            "include_skills_usage_instructions": false,
            "include_apps_usage_instructions": false,
            "include_plugin_usage_instructions": false,
            "supports_search_tool": false,
            "model_messages": ["instructions_template": CodexManagedRuntime.translationInstructions],
        ]
        return try JSONSerialization.data(withJSONObject: ["models": [profile]], options: [.sortedKeys])
    }

    /// Validates selection without resolving or installing the executable package.
    func validate(model: String, effort: String?) throws {
        guard let selected = models.first(where: { $0.slug == model.trimmingCharacters(in: .whitespacesAndNewlines) }),
              effort == nil || selected.supported_reasoning_levels.contains(where: { $0.effort == effort })
        else { throw CodexManagedError.invalidModel }
    }
}
