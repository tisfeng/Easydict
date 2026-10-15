//
//  GitHubCopilotLogger.swift
//  Easydict
//
//  Created by tisfeng on 2026/09/24.
//

import Foundation

// MARK: - GitHubCopilotLogger

/// Writes a structured log file for one `copilot -p` invocation.
///
/// Only captures CLI output; no credential or token is read by Easydict, and the subprocess
/// runs with a disposable `COPILOT_HOME` so its own session files never reach the user's
/// `~/.copilot`.
final class GitHubCopilotLogger: @unchecked Sendable {
    // MARK: Lifecycle

    init(command: String, prompt: String) {
        self.command = command
        self.prompt = prompt

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        self.timestamp = formatter.string(from: Date())

        let fileFormatter = DateFormatter()
        fileFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = fileFormatter.string(from: Date())
        self.fileName = "\(dateString)_\(UUID().uuidString.lowercased()).log"
    }

    // MARK: Internal

    /// Call once after the process is launched to write the request header.
    func start() {
        let header = """
        [REQUEST] \(timestamp)
        Command: \(command)
        Prompt: \(prompt)
        ---
        [STDOUT]
        """
        write(header + "\n")
        GitHubCopilotDebugLogger.shared.post(header)
    }

    /// Call for every stdout chunk received during streaming.
    func appendStdout(_ text: String) {
        write(text)
        GitHubCopilotDebugLogger.shared.post(text)
    }

    /// Call once when the process terminates.
    func finish(stderr: String, exitCode: Int, duration: TimeInterval) {
        let footer = """

        [STDERR] \(stderr.isEmpty ? "(none)" : stderr)
        [EXIT] code=\(exitCode)  duration=\(String(format: "%.1f", duration))s
        """
        write(footer + "\n")
        GitHubCopilotDebugLogger.shared.post(footer)
        pruneOldLogs()
    }

    // MARK: Private

    /// Maximum number of log files to keep; oldest are deleted when exceeded.
    private static let maxLogFiles = 50

    private let command: String
    private let prompt: String
    private let timestamp: String
    private let fileName: String
    private let queue = DispatchQueue(label: "github-copilot-logger", qos: .utility)

    private lazy var fileURL: URL? = {
        let pathManager = AppPathManager.current
        let logDirectory = pathManager.githubCopilotLogDirectory
        try? pathManager.ensureDirectoryExists(at: logDirectory)
        return logDirectory.appendingPathComponent(fileName)
    }()

    /// Deletes the oldest log files once the directory holds more than `maxLogFiles`.
    private func pruneOldLogs() {
        guard let logDirectory = fileURL?.deletingLastPathComponent() else { return }
        queue.async {
            let manager = FileManager.default
            guard let urls = try? manager.contentsOfDirectory(
                at: logDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ) else { return }

            let logFiles = urls.filter { $0.pathExtension == "log" }
            guard logFiles.count > Self.maxLogFiles else { return }

            let sorted = logFiles.sorted { first, second in
                let firstDate = (try? first.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                let secondDate = (try? second.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                return firstDate < secondDate
            }

            let deleteCount = sorted.count - Self.maxLogFiles
            sorted.prefix(deleteCount).forEach { try? manager.removeItem(at: $0) }
        }
    }

    private func write(_ text: String) {
        guard let url = fileURL else { return }
        queue.async {
            guard let data = text.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: url.path) {
                if let handle = try? FileHandle(forWritingTo: url) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }
    }
}

// MARK: - GitHubCopilotDebugLogger

/// Broadcasts log events via `NotificationCenter` so the debug window can observe them
/// without creating a retain cycle between the runner and the window.
final class GitHubCopilotDebugLogger {
    static let shared = GitHubCopilotDebugLogger()

    static let didAppendNotification = Notification.Name("GitHubCopilotDebugLogDidAppend")
    static let textKey = "text"

    /// Posts a log line to all observers (no-op in Release builds).
    func post(_ text: String) {
        #if AGENT_CLI_DEBUG
        NotificationCenter.default.post(
            name: Self.didAppendNotification,
            object: nil,
            userInfo: [Self.textKey: text]
        )
        #endif
    }
}
