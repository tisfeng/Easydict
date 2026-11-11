//
//  CodexLocalCLIInstallation.swift
//  Easydict
//
//  Created by long2ice on 2026/05/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

/// Resolves the executable and environment of a user-installed Codex.
enum CodexLocalCLIInstallation {
    // MARK: Internal

    /// Codex feature flags disabled for translation-only subprocess runs.
    ///
    /// Official references:
    /// - CLI `--disable`: https://developers.openai.com/codex/cli/reference
    /// - Feature flags: https://developers.openai.com/codex/config-basic#feature-flags
    /// - Feature list: https://developers.openai.com/codex/cli/reference#codex-features
    static let disabledToolFeatures = [
        "shell_tool",
        "shell_snapshot",
        "browser_use",
        "browser_use_external",
        "in_app_browser",
        "computer_use",
        "image_generation",
        "apps",
        "plugins",
        "hooks",
        "multi_agent",
        "skill_mcp_dependency_install",
        "tool_call_mcp_elicitation",
        "tool_suggest",
        "workspace_dependencies",
    ]

    /// Runs `which <name>` directly (without a login shell).
    ///
    /// Used by unit tests, which run in an environment where PATH is already set correctly.
    static func runWhich(_ name: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            return nil
        }
    }

    /// Resolves which shell executable should run login-shell detection.
    ///
    /// Accepts the user's configured shell when it is an absolute executable path,
    /// and otherwise falls back to `/bin/zsh`.
    static func resolveLoginShellPath(environmentShell: String?) -> String {
        guard let environmentShell,
              environmentShell.hasPrefix("/"),
              FileManager.default.isExecutableFile(atPath: environmentShell)
        else {
            return "/bin/zsh"
        }
        return environmentShell
    }

    /// Builds the subprocess environment for the Codex CLI invocation.
    ///
    /// Parent values win, but Finder / Dock launches often miss shell-profile values.
    /// The login-shell environment only fills allowlisted auth, Codex home, and proxy
    /// variables that are absent from the parent. `PATH` is merged separately so npm
    /// shebang shims (`#!/usr/bin/env node`) can resolve `node`.
    static func buildProcessEnvironment(
        inheritedEnvironment: [String: String] = ProcessInfo.processInfo.environment,
        loginShellEnvironment: [String: String]? = CodexLocalCLIInstallation.loginShellEnvironment()
    )
        -> [String: String] {
        var environment = inheritedEnvironment
        let merged = mergePathEntries(environment["PATH"], loginShellEnvironment?["PATH"])
        if !merged.isEmpty {
            environment["PATH"] = merged
        }

        for key in loginShellEnvironmentKeys where key != "PATH" {
            guard environment[key] == nil,
                  let value = loginShellEnvironment?[key],
                  !value.isEmpty
            else {
                continue
            }
            environment[key] = value
        }

        return environment
    }

    /// Returns allowlisted variables from the user's login-shell environment.
    ///
    /// The result is cached after the first successful lookup so the login-shell
    /// invocation only happens once per app session.
    ///
    /// The command sources zsh/bash runtime rc files before wrapping allowlisted
    /// `KEY=value` output in sentinels. This lets macOS GUI launches recover
    /// exported auth and network variables from shell profile setup.
    static func loginShellEnvironment() -> [String: String]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = cachedLoginShellEnvironment {
            return cached
        }

        let shellPath = resolveLoginShellPath(
            environmentShell: ProcessInfo.processInfo.environment["SHELL"]
        )
        let command = loginShellEnvironmentCommand(shellPath: shellPath)
        if let output = runViaLoginShell(command, shellPath: shellPath),
           let environment = extractLoginShellEnvironment(from: output) {
            cachedLoginShellEnvironment = environment
            return environment
        }
        return nil
    }

    /// Extracts allowlisted `KEY=value` pairs framed by environment sentinels.
    /// Returns nil when either sentinel is missing.
    static func extractLoginShellEnvironment(from output: String) -> [String: String]? {
        guard let beginRange = output.range(of: environmentSentinelBegin),
              let endRange = output.range(
                  of: environmentSentinelEnd,
                  range: beginRange.upperBound ..< output.endIndex
              )
        else {
            return nil
        }

        var environment: [String: String] = [:]
        let framedOutput = output[beginRange.upperBound ..< endRange.lowerBound]
        for rawEntry in framedOutput.split(separator: "\0", omittingEmptySubsequences: false) {
            let entry = rawEntry.trimmingCharacters(in: .newlines)
            guard !entry.isEmpty,
                  let separatorIndex = entry.firstIndex(of: "=")
            else {
                continue
            }

            let key = String(entry[..<separatorIndex])
            guard loginShellEnvironmentKeys.contains(key) else { continue }

            let valueStart = entry.index(after: separatorIndex)
            environment[key] = String(entry[valueStart...])
        }
        return environment
    }

    /// Builds the shell script used to print allowlisted environment values.
    ///
    /// zsh and bash runtime rc files are sourced silently because macOS GUI apps
    /// often miss variables exported from `~/.zshrc` or `~/.bashrc`.
    static func loginShellEnvironmentCommand(shellPath: String) -> String {
        let keys = loginShellEnvironmentKeys.joined(separator: " ")
        let rcSource = loginShellEnvironmentRCSource(shellPath: shellPath)
        return #"""
        \#(rcSource)
        printf '%s\n' '\#(environmentSentinelBegin)'
        for key in \#(keys); do
          if value=$(/usr/bin/printenv "$key"); then
            printf '%s=%s\0' "$key" "$value"
          fi
        done
        printf '\n%s\n' '\#(environmentSentinelEnd)'
        """#
    }

    /// Returns the path to the first `codex` binary found on this machine.
    ///
    /// The result is cached after the first successful lookup so the login-shell
    /// invocation only happens once per app session. The cached path is revalidated
    /// on each call so that uninstall or upgrade is detected automatically.
    ///
    /// - Throws: `CodexCLIError.notInstalled` if no binary is found.
    static func detectCodexBinary() throws -> String {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = cachedBinaryPath {
            if FileManager.default.isExecutableFile(atPath: cached) {
                return cached
            }
            cachedBinaryPath = nil
        }

        var resolvedPath: String?

        if let raw = runViaLoginShell("which codex") {
            resolvedPath = raw
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first {
                    !$0.isEmpty
                        && URL(fileURLWithPath: $0).lastPathComponent == "codex"
                        && FileManager.default.isExecutableFile(atPath: $0)
                }
        }

        if resolvedPath == nil {
            let candidates = [
                "\(NSHomeDirectory())/.local/bin/codex",
                "\(NSHomeDirectory())/.codex/bin/codex",
                "/usr/local/bin/codex",
                "/opt/homebrew/bin/codex",
            ]
            for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
                resolvedPath = candidate
                break
            }
        }

        if let path = resolvedPath {
            cachedBinaryPath = path
            return path
        }
        throw CodexCLIError.notInstalled
    }

    /// Merges two colon-separated `PATH` strings, preserving order and removing duplicates.
    static func mergePathEntries(_ first: String?, _ second: String?) -> String {
        var seen = Set<String>()
        var result: [String] = []
        for source in [first, second] {
            guard let source else { continue }
            for entry in source.split(separator: ":", omittingEmptySubsequences: true) {
                let value = String(entry)
                if seen.insert(value).inserted {
                    result.append(value)
                }
            }
        }
        return result.joined(separator: ":")
    }

    /// Returns the detected `codex` binary path, or `nil` if not found.
    ///
    /// Used by the configuration view status row.
    static func detectBinaryPath() -> String? {
        try? detectCodexBinary()
    }

    /// Reuse the installed CLI's account, provider and environment.
    static func configureAppServer(_ process: Process) throws {
        let executable = try detectCodexBinary()
        var environment = buildProcessEnvironment()
        environment["RUST_LOG"] = "off"
        process.executableURL = URL(fileURLWithPath: executable)
        process.environment = environment
        process.currentDirectoryURL = FileManager.default.temporaryDirectory
        process.arguments = [
            "app-server", "--listen", "stdio://",
            "-c", #"history.persistence="none""#,
            "-c", #"web_search="disabled""#,
            "-c", "mcp_servers={}",
            "-c", "project_doc_max_bytes=0",
            "-c", "analytics.enabled=false",
            "-c", "feedback.enabled=false",
        ] + disabledToolFeatures.flatMap { ["--disable", $0] }
    }

    // MARK: Private

    /// Cached path from the first successful `detectCodexBinary()` call.
    /// Avoids spawning a login shell on every translation request.
    private static var cachedBinaryPath: String?

    /// Cached login-shell environment from the first successful lookup.
    /// Same caching rationale as `cachedBinaryPath`.
    private static var cachedLoginShellEnvironment: [String: String]?

    /// Login-shell variables that are safe and useful for translation subprocesses.
    private static let loginShellEnvironmentKeys = [
        "PATH", "OPENAI_API_KEY", "CODEX_API_KEY", "CODEX_ACCESS_TOKEN",
        "CODEX_HOME", "CODEX_CA_CERTIFICATE", "SSL_CERT_FILE",
        "HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "NO_PROXY",
        "https_proxy", "http_proxy", "all_proxy", "no_proxy",
    ]

    /// Sentinels used to frame the login-shell environment inside stdout so we
    /// can recover it even when profile scripts print banners on the same stream.
    private static let environmentSentinelBegin = "__EZ_CODEX_ENV_BEGIN__"
    private static let environmentSentinelEnd = "__EZ_CODEX_ENV_END__"

    private static let cacheLock = NSLock()

    private static func loginShellEnvironmentRCSource(shellPath: String) -> String {
        switch URL(fileURLWithPath: shellPath).lastPathComponent {
        case "zsh":
            return #"if [ -r "$HOME/.zshrc" ]; then . "$HOME/.zshrc" >/dev/null 2>/dev/null; fi"#
        case "bash":
            return #"if [ -r "$HOME/.bashrc" ]; then . "$HOME/.bashrc" >/dev/null 2>/dev/null; fi"#
        default:
            return ""
        }
    }

    /// Runs a command via the user's login shell, returning trimmed stdout or nil on failure.
    private static func runViaLoginShell(_ command: String, shellPath: String? = nil) -> String? {
        let shell = shellPath ?? resolveLoginShellPath(
            environmentShell: ProcessInfo.processInfo.environment["SHELL"]
        )
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-l", "-c", command]
        process.standardOutput = pipe
        let devNullHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/dev/null"))
        process.standardError = devNullHandle ?? Pipe()
        do {
            try process.run()
            var outputData = Data()
            let readGroup = DispatchGroup()
            readGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                outputData = pipe.fileHandleForReading.readDataToEndOfFile()
                readGroup.leave()
            }
            process.waitUntilExit()
            try? devNullHandle?.close()
            readGroup.wait()
            guard process.terminationStatus == 0 else { return nil }
            let path = String(data: outputData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            try? devNullHandle?.close()
            return nil
        }
    }
}
