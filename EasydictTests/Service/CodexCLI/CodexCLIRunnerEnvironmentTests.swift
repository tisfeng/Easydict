//
//  CodexCLIRunnerEnvironmentTests.swift
//  EasydictTests
//
//  Created by long2ice on 2026/09/13.
//  Copyright © 2026 izual. All rights reserved.
//

@testable import Easydict
import Foundation
import Testing

private let codexCredentialEnvironmentKeys = [
    "CODEX_API_KEY",
    "CODEX_ACCESS_TOKEN",
    "CODEX_CA_CERTIFICATE",
    "SSL_CERT_FILE",
]

// MARK: - CodexCLIRunnerEnvironmentTests

@Suite("CodexCLIRunner environment")
struct CodexCLIRunnerEnvironmentTests {
    // MARK: - buildProcessEnvironment

    @Test("buildProcessEnvironment merges login-shell PATH after inherited PATH")
    func buildEnvMergesLoginShellPath() {
        let env = CodexCLIRunner.buildProcessEnvironment(
            inheritedEnvironment: ["PATH": "/usr/bin:/bin", "FOO": "bar"],
            loginShellEnvironment: ["PATH": "/opt/homebrew/bin:/usr/local/bin"]
        )
        #expect(env["PATH"] == "/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin")
        #expect(env["FOO"] == "bar")
    }

    @Test("buildProcessEnvironment dedupes entries shared by inherited and login-shell PATH")
    func buildEnvDedupesPathEntries() {
        let env = CodexCLIRunner.buildProcessEnvironment(
            inheritedEnvironment: ["PATH": "/usr/bin:/opt/homebrew/bin"],
            loginShellEnvironment: ["PATH": "/opt/homebrew/bin:/usr/local/bin"]
        )
        #expect(env["PATH"] == "/usr/bin:/opt/homebrew/bin:/usr/local/bin")
    }

    @Test("buildProcessEnvironment leaves PATH unchanged when login-shell PATH is nil")
    func buildEnvKeepsInheritedPathWhenLoginShellMissing() {
        let env = CodexCLIRunner.buildProcessEnvironment(
            inheritedEnvironment: ["PATH": "/usr/bin:/bin"],
            loginShellEnvironment: nil
        )
        #expect(env["PATH"] == "/usr/bin:/bin")
    }

    @Test("buildProcessEnvironment uses login-shell PATH when inherited has none")
    func buildEnvUsesLoginShellPathWhenMissingInherited() {
        let env = CodexCLIRunner.buildProcessEnvironment(
            inheritedEnvironment: ["FOO": "bar"],
            loginShellEnvironment: ["PATH": "/opt/homebrew/bin"]
        )
        #expect(env["PATH"] == "/opt/homebrew/bin")
        #expect(env["FOO"] == "bar")
    }

    @Test("buildProcessEnvironment omits PATH when both sources are nil or empty")
    func buildEnvOmitsPathWhenBothSourcesAbsent() {
        let env = CodexCLIRunner.buildProcessEnvironment(
            inheritedEnvironment: ["FOO": "bar"],
            loginShellEnvironment: nil
        )
        #expect(env["PATH"] == nil)
        #expect(env["FOO"] == "bar")
    }

    @Test("buildProcessEnvironment fills allowlisted login-shell variables")
    func buildEnvFillsAllowlistedLoginShellVariables() {
        let env = CodexCLIRunner.buildProcessEnvironment(
            inheritedEnvironment: ["PATH": "/usr/bin", "FOO": "bar"],
            loginShellEnvironment: [
                "PATH": "/opt/homebrew/bin",
                "OPENAI_API_KEY": "login-key",
                "CODEX_API_KEY": "login-codex-key",
                "CODEX_ACCESS_TOKEN": "login-access-token",
                "CODEX_HOME": "/Users/test/.codex-custom",
                "CODEX_CA_CERTIFICATE": "/Users/test/codex-ca.pem",
                "SSL_CERT_FILE": "/Users/test/ssl-ca.pem",
                "HTTPS_PROXY": "http://127.0.0.1:7890",
                "HTTP_PROXY": "http://127.0.0.1:7891",
                "ALL_PROXY": "socks5://127.0.0.1:7892",
                "NO_PROXY": "localhost,127.0.0.1",
                "https_proxy": "http://127.0.0.1:8890",
                "http_proxy": "http://127.0.0.1:8891",
                "all_proxy": "socks5://127.0.0.1:8892",
                "no_proxy": "localhost",
                "SHELL": "/bin/zsh",
            ]
        )

        #expect(env["PATH"] == "/usr/bin:/opt/homebrew/bin")
        #expect(env["OPENAI_API_KEY"] == "login-key")
        #expect(env["CODEX_API_KEY"] == "login-codex-key")
        #expect(env["CODEX_ACCESS_TOKEN"] == "login-access-token")
        #expect(env["CODEX_HOME"] == "/Users/test/.codex-custom")
        #expect(env["CODEX_CA_CERTIFICATE"] == "/Users/test/codex-ca.pem")
        #expect(env["SSL_CERT_FILE"] == "/Users/test/ssl-ca.pem")
        #expect(env["HTTPS_PROXY"] == "http://127.0.0.1:7890")
        #expect(env["HTTP_PROXY"] == "http://127.0.0.1:7891")
        #expect(env["ALL_PROXY"] == "socks5://127.0.0.1:7892")
        #expect(env["NO_PROXY"] == "localhost,127.0.0.1")
        #expect(env["https_proxy"] == "http://127.0.0.1:8890")
        #expect(env["http_proxy"] == "http://127.0.0.1:8891")
        #expect(env["all_proxy"] == "socks5://127.0.0.1:8892")
        #expect(env["no_proxy"] == "localhost")
        #expect(env["SHELL"] == nil)
        #expect(env["FOO"] == "bar")
    }

    @Test("buildProcessEnvironment keeps inherited values before login-shell values")
    func buildEnvKeepsInheritedAllowlistedValues() {
        let env = CodexCLIRunner.buildProcessEnvironment(
            inheritedEnvironment: [
                "OPENAI_API_KEY": "parent-key",
                "CODEX_API_KEY": "parent-codex-key",
                "CODEX_ACCESS_TOKEN": "",
                "CODEX_HOME": "",
                "CODEX_CA_CERTIFICATE": "parent-ca.pem",
                "https_proxy": "http://parent.proxy",
            ],
            loginShellEnvironment: [
                "OPENAI_API_KEY": "login-key",
                "CODEX_API_KEY": "login-codex-key",
                "CODEX_ACCESS_TOKEN": "login-access-token",
                "CODEX_HOME": "/Users/test/.codex",
                "CODEX_CA_CERTIFICATE": "login-ca.pem",
                "SSL_CERT_FILE": "login-ssl.pem",
                "https_proxy": "http://login.proxy",
                "http_proxy": "http://login-lower.proxy",
            ]
        )

        #expect(env["OPENAI_API_KEY"] == "parent-key")
        #expect(env["CODEX_API_KEY"] == "parent-codex-key")
        #expect(env["CODEX_ACCESS_TOKEN"] == "")
        #expect(env["CODEX_HOME"] == "")
        #expect(env["CODEX_CA_CERTIFICATE"] == "parent-ca.pem")
        #expect(env["SSL_CERT_FILE"] == "login-ssl.pem")
        #expect(env["https_proxy"] == "http://parent.proxy")
        #expect(env["http_proxy"] == "http://login-lower.proxy")
    }

    // MARK: - loginShellEnvironmentCommand

    @Test("loginShellEnvironmentCommand sources zshrc before env sentinels")
    func loginShellEnvironmentCommandSourcesZshrc() {
        let command = CodexCLIRunner.loginShellEnvironmentCommand(shellPath: "/bin/zsh")

        #expect(command.contains(#". "$HOME/.zshrc" >/dev/null 2>/dev/null"#))
        for key in codexCredentialEnvironmentKeys {
            #expect(command.contains(key))
        }
        if let sourceIndex = command.range(of: ".zshrc")?.lowerBound,
           let sentinelIndex = command.range(of: "__EZ_CODEX_ENV_BEGIN__")?.lowerBound {
            #expect(sourceIndex < sentinelIndex)
        }
    }

    @Test("loginShellEnvironmentCommand sources bashrc before env sentinels")
    func loginShellEnvironmentCommandSourcesBashrc() {
        let command = CodexCLIRunner.loginShellEnvironmentCommand(shellPath: "/bin/bash")

        #expect(command.contains(#". "$HOME/.bashrc" >/dev/null 2>/dev/null"#))
        #expect(!command.contains(".zshrc"))
        if let sourceIndex = command.range(of: ".bashrc")?.lowerBound,
           let sentinelIndex = command.range(of: "__EZ_CODEX_ENV_BEGIN__")?.lowerBound {
            #expect(sourceIndex < sentinelIndex)
        }
    }

    @Test("loginShellEnvironmentCommand does not source rc for unknown shells")
    func loginShellEnvironmentCommandSkipsUnknownShellRc() {
        let command = CodexCLIRunner.loginShellEnvironmentCommand(shellPath: "/usr/local/bin/fish")

        #expect(!command.contains(".zshrc"))
        #expect(!command.contains(".bashrc"))
        #expect(command.contains("__EZ_CODEX_ENV_BEGIN__"))
    }

    @Test("mergePathEntries trims empty colon-separated segments")
    func mergePathEntriesTrimsEmptySegments() {
        let merged = CodexCLIRunner.mergePathEntries("/usr/bin::/bin", ":/opt/homebrew/bin:")
        #expect(merged == "/usr/bin:/bin:/opt/homebrew/bin")
    }

    // MARK: - extractLoginShellEnvironment

    @Test("extractLoginShellEnvironment ignores banner noise before the begin sentinel")
    func extractEnvironmentIgnoresBanner() {
        let stdout = framedLoginShellEnvironment(
            [
                "PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
                "OPENAI_API_KEY=sk-test=value",
                "CODEX_API_KEY=codex-test-key",
                "CODEX_HOME=/Users/test/Codex Home",
                "SHELL=/bin/zsh",
            ],
            banner: "Welcome to my zsh init\nSourcing oh-my-zsh plugins..."
        )
        let env = CodexCLIRunner.extractLoginShellEnvironment(from: stdout)
        #expect(env?["PATH"] == "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin")
        #expect(env?["OPENAI_API_KEY"] == "sk-test=value")
        #expect(env?["CODEX_API_KEY"] == "codex-test-key")
        #expect(env?["CODEX_HOME"] == "/Users/test/Codex Home")
        #expect(env?["SHELL"] == nil)
    }

    @Test("extractLoginShellEnvironment returns nil when sentinels are missing")
    func extractEnvironmentMissingSentinels() {
        #expect(CodexCLIRunner.extractLoginShellEnvironment(from: "PATH=/usr/bin:/bin") == nil)
    }

    @Test("extractLoginShellEnvironment returns nil when only one sentinel is present")
    func extractEnvironmentOnlyOneSentinel() {
        let stdout = "noise __EZ_CODEX_ENV_BEGIN__ PATH=/usr/bin"
        #expect(CodexCLIRunner.extractLoginShellEnvironment(from: stdout) == nil)
    }

    @Test("extractLoginShellEnvironment ignores non-allowlisted variables")
    func extractEnvironmentIgnoresNonAllowlistedVariables() {
        let stdout = framedLoginShellEnvironment([
            "SHELL=/bin/zsh",
            "HOME=/Users/test",
        ])
        let env = CodexCLIRunner.extractLoginShellEnvironment(from: stdout)
        #expect(env?.isEmpty == true)
    }

    @Test("extractLoginShellEnvironment preserves spaces inside values")
    func extractEnvironmentPreservesSpacesInValues() {
        let stdout = framedLoginShellEnvironment([
            "CODEX_HOME=/Users/test/Codex Home",
            "PATH=/Applications/Some Tool.app/Contents/MacOS:/usr/bin",
        ])
        let env = CodexCLIRunner.extractLoginShellEnvironment(from: stdout)
        #expect(env?["CODEX_HOME"] == "/Users/test/Codex Home")
        #expect(env?["PATH"] == "/Applications/Some Tool.app/Contents/MacOS:/usr/bin")
    }
}

private func framedLoginShellEnvironment(
    _ entries: [String],
    banner: String = ""
)
    -> String {
    [
        banner,
        "__EZ_CODEX_ENV_BEGIN__",
        entries.joined(separator: "\0") + "\0",
        "__EZ_CODEX_ENV_END__",
    ]
    .filter { !$0.isEmpty }
    .joined(separator: "\n")
}
