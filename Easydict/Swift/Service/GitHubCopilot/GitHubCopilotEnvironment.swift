//
//  GitHubCopilotEnvironment.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/26.
//

import Foundation

/// Restores the CLI launch context that Finder and Xcode do not inherit from the user's shell.
enum GitHubCopilotEnvironment {
    // MARK: Internal

    /// Parent values win; the login shell fills only authentication and network configuration.
    /// PATH is merged so CLI dependencies, including the `gh` authentication fallback, are found.
    static func resolve() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let shellEnvironment = loginShellEnvironment()
        var paths: [String] = []
        for path in [environment["PATH"], shellEnvironment?["PATH"]].compactMap({ $0 }) {
            for entry in path.split(separator: ":").map(String.init) where !paths.contains(entry) {
                paths.append(entry)
            }
        }
        if !paths.isEmpty {
            environment["PATH"] = paths.joined(separator: ":")
        }
        for key in shellKeys where key != "PATH" && environment[key] == nil {
            if let value = shellEnvironment?[key], !value.isEmpty {
                environment[key] = value
            }
        }
        environment.removeValue(forKey: "COPILOT_ALLOW_ALL")
        return environment
    }

    /// Copies only account identifiers into the disposable home. The CLI uses them to look up
    /// its own keychain entries. Decode and encode typed fields so tokens, hooks, plugins, and
    /// trusted directories can never be carried over from the user's application state.
    /// Read on every request so a subsequent `copilot login` or account switch takes effect.
    static func prepareAuthentication(in directory: URL, environment: [String: String]) throws {
        let userHome = environment["HOME"] ?? NSHomeDirectory()
        let configuredHome = environment["COPILOT_HOME"].flatMap { $0.isEmpty ? nil : $0 }
            ?? (userHome as NSString).appendingPathComponent(".copilot")
        let source = URL(fileURLWithPath: (configuredHome as NSString).expandingTildeInPath)
            .appendingPathComponent("config.json")
        guard FileManager.default.fileExists(atPath: source.path) else { return }

        let decoder = JSONDecoder()
        decoder.allowsJSON5 = true
        let state = try decoder.decode(AccountState.self, from: Data(contentsOf: source))
        guard state.lastLoggedInUser != nil || state.loggedInUsers?.isEmpty == false else { return }

        let destination = directory.appendingPathComponent("config.json")
        try JSONEncoder().encode(state).write(to: destination, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destination.path)
    }

    // MARK: Private

    private struct Account: Codable {
        let host: String
        let login: String
    }

    private struct AccountState: Codable {
        let lastLoggedInUser: Account?
        let loggedInUsers: [Account]?
    }

    private static let shellKeys = [
        "PATH", "COPILOT_HOME", "COPILOT_GITHUB_TOKEN", "GH_TOKEN", "GITHUB_TOKEN",
        "COPILOT_GH_HOST", "GH_HOST", "GH_CONFIG_DIR", "SSL_CERT_FILE", "NODE_EXTRA_CA_CERTS",
        "HTTPS_PROXY", "HTTP_PROXY", "ALL_PROXY", "NO_PROXY",
        "https_proxy", "http_proxy", "all_proxy", "no_proxy",
    ]
    private static let beginMarker = "__EZ_COPILOT_ENV_BEGIN__"
    private static let endMarker = "__EZ_COPILOT_ENV_END__"
    private static let lock = NSLock()
    private static var cachedShellEnvironment: [String: String]?

    /// Match Codex's shell recovery without importing unrelated Codex credentials.
    /// Shell output is kept in memory and never logged because it may contain tokens.
    private static func loginShellEnvironment() -> [String: String]? {
        lock.lock()
        defer { lock.unlock() }
        if let cachedShellEnvironment { return cachedShellEnvironment }

        let shell = GitHubCopilotRunner.resolveLoginShellPath(
            environmentShell: ProcessInfo.processInfo.environment["SHELL"]
        )
        let sourceRC: String
        switch URL(fileURLWithPath: shell).lastPathComponent {
        case "zsh":
            sourceRC = #"if [ -r "$HOME/.zshrc" ]; then . "$HOME/.zshrc" >/dev/null 2>/dev/null; fi"#
        case "bash":
            sourceRC = #"if [ -r "$HOME/.bashrc" ]; then . "$HOME/.bashrc" >/dev/null 2>/dev/null; fi"#
        default:
            sourceRC = ""
        }
        let command = #"""
        \#(sourceRC)
        printf '%s\n' '\#(beginMarker)'
        for key in \#(shellKeys.joined(separator: " ")); do
          if value=$(/usr/bin/printenv "$key"); then
            printf '%s=%s\0' "$key" "$value"
          fi
        done
        printf '\n%s\n' '\#(endMarker)'
        """#
        guard let output = GitHubCopilotRunner.runViaLoginShell(command),
              let begin = output.range(of: beginMarker),
              let end = output.range(of: endMarker, range: begin.upperBound ..< output.endIndex)
        else { return nil }

        var environment: [String: String] = [:]
        for rawEntry in output[begin.upperBound ..< end.lowerBound].split(separator: "\0") {
            let entry = rawEntry.trimmingCharacters(in: .newlines)
            guard let separator = entry.firstIndex(of: "=") else { continue }
            let key = String(entry[..<separator])
            guard shellKeys.contains(key) else { continue }
            environment[key] = String(entry[entry.index(after: separator)...])
        }
        cachedShellEnvironment = environment
        return environment
    }
}
