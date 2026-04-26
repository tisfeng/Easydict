//
//  ClaudeCodeLogger.swift
//  Easydict
//
//  Created by Karl on 2026/04/07.
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation

// MARK: - ClaudeCodeLogger

/// Writes a structured log file for one `claude -p` invocation.
final class ClaudeCodeLogger: @unchecked Sendable {
    // MARK: Lifecycle

    init(command: String, prompt: String) {
        self.command = command
        self.prompt = prompt

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        self.timestamp = formatter.string(from: Date())

        let fileFormatter = DateFormatter()
        fileFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateStr = fileFormatter.string(from: Date())
        let uuid = UUID().uuidString.lowercased()
        self.fileName = "\(dateStr)_\(uuid).log"
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
        ClaudeCodeDebugLogger.shared.post(header)
    }

    /// Call for every stdout chunk received during streaming.
    func appendStdout(_ text: String) {
        write(text)
        ClaudeCodeDebugLogger.shared.post(text)
    }

    /// Call once when the process terminates.
    func finish(stderr: String, exitCode: Int, duration: TimeInterval) {
        let footer = """

        [STDERR] \(stderr.isEmpty ? "(none)" : stderr)
        [EXIT] code=\(exitCode)  duration=\(String(format: "%.1f", duration))s
        """
        write(footer + "\n")
        ClaudeCodeDebugLogger.shared.post(footer)
        pruneOldLogs()
    }

    // MARK: Private

    /// Maximum number of log files to keep. Oldest files are deleted when exceeded.
    private static let maxLogFiles = 50

    private let command: String
    private let prompt: String
    private let timestamp: String
    private let fileName: String
    private let queue = DispatchQueue(label: "claude-code-logger", qos: .utility)

    private lazy var fileURL: URL? = {
        guard let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else { return nil }
        let logDir = base
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "Easydict")
            .appendingPathComponent("logs")
            .appendingPathComponent("claude-code")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        return logDir.appendingPathComponent(fileName)
    }()

    /// Deletes the oldest log files in the log directory when the count exceeds `maxLogFiles`.
    private func pruneOldLogs() {
        guard let logDir = fileURL?.deletingLastPathComponent() else { return }
        queue.async {
            let fm = FileManager.default
            guard let urls = try? fm.contentsOfDirectory(
                at: logDir,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            ) else { return }

            let logFiles = urls.filter { $0.pathExtension == "log" }
            guard logFiles.count > Self.maxLogFiles else { return }

            // Sort oldest first.
            let sorted = logFiles.sorted { argA, argB in
                let dateA = (try? argA.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                let dateB = (try? argB.resourceValues(forKeys: [.contentModificationDateKey]))?
                    .contentModificationDate ?? .distantPast
                return dateA < dateB
            }

            let deleteCount = sorted.count - Self.maxLogFiles
            sorted.prefix(deleteCount).forEach { try? fm.removeItem(at: $0) }
        }
    }

    private func write(_ text: String) {
        guard let url = fileURL else { return }
        queue.async {
            if let data = text.data(using: .utf8) {
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
}

// MARK: - ClaudeCodeDebugLogger

/// Broadcasts log events via `NotificationCenter` so the debug window can observe them
/// without creating a retain cycle between the runner and the window.
final class ClaudeCodeDebugLogger {
    static let shared = ClaudeCodeDebugLogger()

    static let didAppendNotification = Notification.Name("ClaudeCodeDebugLogDidAppend")
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
