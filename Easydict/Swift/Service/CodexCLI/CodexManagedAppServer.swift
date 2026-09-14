//
//  CodexManagedAppServer.swift
//  Easydict
//
//  Created by Alfred on 2026/09/14.
//

import Foundation

// MARK: - CodexManagedAppServer

/// Reuses one application-owned Codex App Server while keeping every translation
/// in an independent ephemeral thread. Requests are multiplexed by thread and turn
/// identifiers so cancellation never terminates work owned by another window.
actor CodexManagedAppServer {
    // MARK: Internal

    struct TranslationRequest: @unchecked Sendable {
        let identifier: UUID
        let prompt: String
        let model: String
        let effort: String?
        let runtime: CodexManagedRuntime
        let isCancelled: @Sendable () -> Bool
        let deltaReceived: @Sendable (String) -> ()
    }

    static let shared = CodexManagedAppServer()
    static let providerID = "easydict"

    func runtime() async throws -> CodexManagedRuntime {
        if let session { return session.runtime }
        if let cachedRuntime { return cachedRuntime }
        if let runtimeLoad { return try await runtimeLoad.task.value }

        let identifier = UUID()
        let task = Task.detached(priority: .userInitiated) {
            try await CodexManagedRuntime.installed()
        }
        runtimeLoad = (identifier, task)
        do {
            let runtime = try await task.value
            if runtimeLoad?.identifier == identifier {
                runtimeLoad = nil
                cachedRuntime = runtime
                scheduleIdleShutdown()
            }
            return runtime
        } catch {
            if runtimeLoad?.identifier == identifier { runtimeLoad = nil }
            throw error
        }
    }

    func translate(_ translation: TranslationRequest) async throws
        -> CodexManagedTranslation.Result {
        try Task.checkCancellation()
        guard !translation.isCancelled() else { throw CancellationError() }
        try CodexManagedRuntime.validateSelection(model: translation.model, effort: translation.effort)

        idleTask?.cancel()
        idleTask = nil
        let session = try await ensureSession(runtime: translation.runtime)
        try Task.checkCancellation()
        guard !translation.isCancelled() else { throw CancellationError() }

        let state = TranslationState(
            identifier: translation.identifier,
            sessionIdentifier: session.identifier,
            deltaReceived: translation.deltaReceived
        )
        translations[translation.identifier] = state
        state.timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.translationTimeout))
            guard !Task.isCancelled else { return }
            await self?.timeout(translation.identifier)
        }

        do {
            let response = try await request(
                session: session,
                method: "thread/start",
                params: threadParameters(model: translation.model, runtime: translation.runtime),
                translationIdentifier: translation.identifier
            )
            guard translations[translation.identifier] === state,
                  let thread = response.object["thread"] as? [String: Any],
                  let threadID = thread["id"] as? String,
                  thread["ephemeral"] as? Bool == true
            else { throw state.failure ?? CodexManagedError.invalidResponse }
            state.threadID = threadID
            requestByThread[threadID] = translation.identifier
            if let failure = state.failure { throw failure }

            var turnParameters: [String: Any] = [
                "threadId": threadID,
                "input": [["type": "text", "text": translation.prompt]],
            ]
            if let effort = translation.effort { turnParameters["effort"] = effort }
            let turnResponse = try await request(
                session: session,
                method: "turn/start",
                params: turnParameters,
                translationIdentifier: translation.identifier
            )
            guard translations[translation.identifier] === state,
                  let turn = turnResponse.object["turn"] as? [String: Any],
                  let turnID = turn["id"] as? String
            else { throw state.failure ?? CodexManagedError.invalidResponse }
            if let eventTurnID = state.turnID, eventTurnID != turnID {
                throw CodexManagedError.invalidResponse
            }
            state.turnID = turnID
            if let failure = state.failure {
                interrupt(state, session: session)
                throw failure
            }
            return try await result(for: state)
        } catch {
            if translations[translation.identifier] === state {
                discard(state, releaseThread: true)
            }
            throw error
        }
    }

    func cancel(_ requestID: UUID) {
        guard let state = translations[requestID] else { return }
        guard state.failure == nil else { return }
        state.failure = CancellationError()
        // Start responses carry the identifiers needed for targeted cleanup. Keep
        // them correlated until translate() can recover the IDs and interrupt.
        if state.threadID != nil, state.turnID != nil {
            cancelPendingResponses(for: requestID, error: CancellationError())
        }
        if let session, session.identifier == state.sessionIdentifier {
            interrupt(state, session: session)
        }
        if state.continuation != nil {
            finish(state, result: .failure(CancellationError()), releaseThread: true)
        }
    }

    /// Stops the shared process before credentials or managed component identity changes.
    func invalidate() {
        runtimeLoad?.task.cancel()
        runtimeLoad = nil
        cachedRuntime = nil
        stopSession(error: CancellationError())
    }

    // MARK: Private

    private struct RPCResponse: @unchecked Sendable {
        let object: [String: Any]
    }

    private struct PendingResponse {
        let sessionIdentifier: UUID
        let translationIdentifier: UUID?
        let continuation: CheckedContinuation<RPCResponse, Error>
        let timeoutTask: Task<(), Never>
    }

    private final class Session {
        // MARK: Lifecycle

        init(runtime: CodexManagedRuntime, process: CodexManagedAppServerProcess) {
            self.runtime = runtime
            self.process = process
        }

        // MARK: Internal

        let identifier = UUID()
        let runtime: CodexManagedRuntime
        let process: CodexManagedAppServerProcess
        let messages = MessageChannel()
        var initialized = false
        var messageTask: Task<(), Never>?
        var readiness: [CheckedContinuation<(), Error>] = []
    }

    private final class MessageChannel: @unchecked Sendable {
        // MARK: Lifecycle

        init() {
            var captured: AsyncStream<Data>.Continuation?
            self.stream = AsyncStream { captured = $0 }
            self.continuation = captured!
        }

        // MARK: Internal

        let stream: AsyncStream<Data>
        let continuation: AsyncStream<Data>.Continuation
    }

    private final class TranslationState {
        // MARK: Lifecycle

        init(
            identifier: UUID,
            sessionIdentifier: UUID,
            deltaReceived: @escaping @Sendable (String) -> ()
        ) {
            self.identifier = identifier
            self.sessionIdentifier = sessionIdentifier
            self.deltaReceived = deltaReceived
            self.started = ProcessInfo.processInfo.systemUptime
        }

        // MARK: Internal

        let identifier: UUID
        let sessionIdentifier: UUID
        let deltaReceived: @Sendable (String) -> ()
        let started: TimeInterval
        var threadID: String?
        var turnID: String?
        var streamedText = ""
        var completedText: String?
        var usage: CodexTokenUsage?
        var failure: Error?
        var continuation: CheckedContinuation<CodexManagedTranslation.Result, Error>?
        var completedResult: Result<CodexManagedTranslation.Result, Error>?
        var timeoutTask: Task<(), Never>?
        var threadReleased = false
    }

    private static let translationTimeout: TimeInterval = 120
    private static let requestTimeout: TimeInterval = 30
    private static let idleTimeout: TimeInterval = 300
    private static let allowedItemTypes = ["userMessage", "reasoning", "agentMessage"]

    private var session: Session?
    private var cachedRuntime: CodexManagedRuntime?
    private var runtimeLoad: (identifier: UUID, task: Task<CodexManagedRuntime, Error>)?
    private var nextRequestID = 1
    private var pendingResponses: [Int: PendingResponse] = [:]
    private var translations: [UUID: TranslationState] = [:]
    private var requestByThread: [String: UUID] = [:]
    private var idleTask: Task<(), Never>?
}

extension CodexManagedAppServer {
    private static func translationError(_ message: String?) -> Error {
        guard let message = message?.trimmingCharacters(in: .whitespacesAndNewlines),
              !message.isEmpty
        else { return CodexManagedError.invalidResponse }
        let lowercased = message.lowercased()
        if lowercased.contains("keyring") || lowercased.contains("keychain") {
            return CodexManagedError.keychainUnavailable
        }
        if lowercased.contains("not signed in") || lowercased.contains("not logged in")
            || lowercased.contains("please run `codex login`") || lowercased.contains("please run codex login") {
            return CodexManagedError.loginRequired
        }
        if lowercased.contains("authentication_failed") || lowercased.contains("authentication failed")
            || lowercased.contains("unauthorized") || lowercased.contains("not authenticated")
            || lowercased.contains("openai_api_key") || lowercased.contains("invalid api key")
            || lowercased.contains("401") {
            return CodexManagedError.authenticationFailed
        }
        if lowercased.contains("rate limit") || lowercased.contains("quota")
            || lowercased.contains("usage limit") || lowercased.contains("insufficient_quota")
            || lowercased.contains("insufficient quota") || lowercased.contains("credit")
            || lowercased.contains("429") {
            return CodexCLIError.quotaExceeded(message: message)
        }
        return CodexCLIError.cliError(message: message)
    }

    private func ensureSession(runtime: CodexManagedRuntime) async throws -> Session {
        if let session, runtimeMatches(runtime, session.runtime) {
            if session.initialized { return session }
            try await withCheckedThrowingContinuation { continuation in
                session.readiness.append(continuation)
            }
            guard self.session === session, session.initialized else {
                throw CodexManagedError.invalidResponse
            }
            return session
        }
        if session != nil { stopSession(error: CancellationError()) }

        let process = CodexManagedAppServerProcess(runtime: runtime)
        let session = Session(runtime: runtime, process: process)
        self.session = session
        cachedRuntime = runtime
        session.messageTask = Task { [weak self, weak session] in
            guard let session else { return }
            for await data in session.messages.stream {
                guard !Task.isCancelled else { return }
                await self?.receive(data, from: session.process.identifier)
            }
        }
        do {
            try process.start(
                messageReceived: { [weak session] data in
                    session?.messages.continuation.yield(data)
                },
                terminated: { [weak self, weak session] stderr in
                    guard let session else { return }
                    session.messages.continuation.finish()
                    Task {
                        await session.messageTask?.value
                        await self?.processTerminated(session.process.identifier, stderr: stderr)
                    }
                }
            )
            _ = try await request(
                session: session,
                method: "initialize",
                params: [
                    "clientInfo": [
                        "name": "easydict",
                        "title": "Easydict",
                        "version": Bundle.main
                            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                    ],
                ]
            )
            try process.send(["method": "initialized"])
            guard self.session === session else { throw CancellationError() }
            session.initialized = true
            let readiness = session.readiness
            session.readiness.removeAll()
            readiness.forEach { $0.resume() }
            return session
        } catch {
            failSession(session, error: error, terminate: true)
            throw error
        }
    }

    private func request(
        session: Session,
        method: String,
        params: [String: Any],
        translationIdentifier: UUID? = nil
    ) async throws
        -> RPCResponse {
        guard self.session === session else { throw CodexManagedError.invalidResponse }
        let identifier = nextRequestID
        nextRequestID &+= 1
        return try await withCheckedThrowingContinuation { continuation in
            let sessionIdentifier = session.identifier
            let timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(Self.requestTimeout))
                guard !Task.isCancelled else { return }
                await self?.requestTimedOut(identifier, sessionIdentifier: sessionIdentifier)
            }
            pendingResponses[identifier] = PendingResponse(
                sessionIdentifier: sessionIdentifier,
                translationIdentifier: translationIdentifier,
                continuation: continuation,
                timeoutTask: timeoutTask
            )
            do {
                try session.process.send([
                    "id": identifier,
                    "method": method,
                    "params": params,
                ])
            } catch {
                pendingResponses.removeValue(forKey: identifier)?.timeoutTask.cancel()
                continuation.resume(throwing: error)
                failSession(session, error: error, terminate: true)
            }
        }
    }

    private func sendWithoutWaiting(
        session: Session,
        method: String,
        params: [String: Any]
    ) {
        guard self.session === session else { return }
        let identifier = nextRequestID
        nextRequestID &+= 1
        do {
            try session.process.send([
                "id": identifier,
                "method": method,
                "params": params,
            ])
        } catch {
            failSession(session, error: error, terminate: true)
        }
    }

    private func receive(_ data: Data, from processIdentifier: UUID) {
        guard let session, session.process.identifier == processIdentifier else { return }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            failSession(session, error: CodexManagedError.invalidResponse, terminate: true)
            return
        }
        if object["method"] != nil, object["id"] != nil {
            // Translation mode disables tools and approvals, so a server-initiated
            // request means the isolation contract was not honored.
            failSession(session, error: CodexManagedError.invalidResponse, terminate: true)
            return
        }
        if let responseID = (object["id"] as? NSNumber)?.intValue,
           let pending = pendingResponses.removeValue(forKey: responseID) {
            pending.timeoutTask.cancel()
            guard pending.sessionIdentifier == session.identifier else {
                pending.continuation.resume(throwing: CodexManagedError.invalidResponse)
                return
            }
            if let error = object["error"] as? [String: Any] {
                pending.continuation.resume(throwing: Self.translationError(error["message"] as? String))
            } else if let result = object["result"] as? [String: Any] {
                pending.continuation.resume(returning: RPCResponse(object: result))
            } else {
                pending.continuation.resume(throwing: CodexManagedError.invalidResponse)
            }
            return
        }
        guard let method = object["method"] as? String,
              let params = object["params"] as? [String: Any]
        else { return }
        receiveNotification(method: method, params: params, session: session)
    }

    private func receiveNotification(method: String, params: [String: Any], session: Session) {
        guard let threadID = params["threadId"] as? String,
              let requestID = requestByThread[threadID],
              let state = translations[requestID],
              state.sessionIdentifier == session.identifier
        else { return }
        if let eventTurnID = params["turnId"] as? String,
           let turnID = state.turnID {
            if eventTurnID != turnID { return }
        } else if let eventTurnID = params["turnId"] as? String {
            state.turnID = eventTurnID
        }

        switch method {
        case "item/agentMessage/delta":
            guard state.failure == nil, let delta = params["delta"] as? String else { return }
            state.streamedText += delta
            state.deltaReceived(delta)
        case "item/completed", "item/started":
            guard let item = params["item"] as? [String: Any], validate(item: item) else {
                fail(state, error: CodexManagedError.invalidResponse, session: session)
                return
            }
            if method == "item/completed", item["type"] as? String == "agentMessage" {
                state.completedText = item["text"] as? String
            }
        case "thread/tokenUsage/updated":
            state.usage = tokenUsage(from: params, durationMs: elapsedMilliseconds(state))
        case "turn/completed":
            completeTurn(state, params: params, session: session)
        default:
            break
        }
    }

    private func completeTurn(
        _ state: TranslationState,
        params: [String: Any],
        session: Session
    ) {
        guard let turn = params["turn"] as? [String: Any],
              let turnID = turn["id"] as? String,
              state.turnID == turnID,
              let status = turn["status"] as? String
        else {
            fail(state, error: CodexManagedError.invalidResponse, session: session)
            return
        }
        if status == "interrupted" {
            fail(state, error: state.failure ?? CancellationError(), session: session)
            return
        }
        if status == "failed" {
            let message = (turn["error"] as? [String: Any])?["message"] as? String
            fail(state, error: Self.translationError(message), session: session)
            return
        }
        guard status == "completed",
              let items = turn["items"] as? [[String: Any]],
              items.allSatisfy({ validate(item: $0) })
        else {
            fail(state, error: CodexManagedError.invalidResponse, session: session)
            return
        }
        let finalText = items.compactMap { item -> String? in
            guard item["type"] as? String == "agentMessage" else { return nil }
            return item["text"] as? String
        }.last ?? state.completedText ?? state.streamedText
        guard !finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fail(state, error: CodexManagedError.invalidResponse, session: session)
            return
        }
        if state.streamedText.isEmpty {
            state.deltaReceived(finalText)
        } else if finalText.hasPrefix(state.streamedText) {
            let suffix = String(finalText.dropFirst(state.streamedText.count))
            if !suffix.isEmpty { state.deltaReceived(suffix) }
        } else if finalText != state.streamedText {
            fail(state, error: CodexManagedError.invalidResponse, session: session)
            return
        }
        let result = CodexManagedTranslation.Result(
            text: finalText,
            usage: state.usage.map {
                CodexTokenUsage(
                    inputTokens: $0.inputTokens,
                    cachedInputTokens: $0.cachedInputTokens,
                    outputTokens: $0.outputTokens,
                    reasoningOutputTokens: $0.reasoningOutputTokens,
                    durationMs: elapsedMilliseconds(state)
                )
            }
        )
        finish(state, result: .success(result), releaseThread: true)
    }

    private func result(for state: TranslationState) async throws
        -> CodexManagedTranslation.Result {
        if let completedResult = state.completedResult {
            discard(state, releaseThread: false)
            return try completedResult.get()
        }
        if let failure = state.failure {
            discard(state, releaseThread: true)
            throw failure
        }
        return try await withCheckedThrowingContinuation { continuation in
            state.continuation = continuation
        }
    }

    private func timeout(_ requestID: UUID) {
        guard let state = translations[requestID], state.failure == nil else { return }
        state.failure = CodexManagedError.timeout
        if let session, session.identifier == state.sessionIdentifier {
            interrupt(state, session: session)
        }
        if state.continuation != nil {
            finish(state, result: .failure(CodexManagedError.timeout), releaseThread: true)
        }
    }

    private func requestTimedOut(_ identifier: Int, sessionIdentifier: UUID) {
        guard let response = pendingResponses[identifier],
              response.sessionIdentifier == sessionIdentifier,
              let session,
              session.identifier == sessionIdentifier
        else { return }
        pendingResponses.removeValue(forKey: identifier)
        response.continuation.resume(throwing: CodexManagedError.timeout)
        failSession(session, error: CodexManagedError.timeout, terminate: true)
    }

    private func cancelPendingResponses(for translationIdentifier: UUID, error: Error) {
        let matches = pendingResponses.filter {
            $0.value.translationIdentifier == translationIdentifier
        }
        for (identifier, response) in matches {
            pendingResponses.removeValue(forKey: identifier)
            response.timeoutTask.cancel()
            response.continuation.resume(throwing: error)
        }
    }

    private func interrupt(_ state: TranslationState, session: Session) {
        guard let threadID = state.threadID, let turnID = state.turnID else { return }
        sendWithoutWaiting(
            session: session,
            method: "turn/interrupt",
            params: ["threadId": threadID, "turnId": turnID]
        )
    }

    private func fail(_ state: TranslationState, error: Error, session: Session) {
        state.failure = error
        interrupt(state, session: session)
        finish(state, result: .failure(error), releaseThread: true)
    }

    private func finish(
        _ state: TranslationState,
        result: Result<CodexManagedTranslation.Result, Error>,
        releaseThread: Bool
    ) {
        guard translations[state.identifier] === state else { return }
        state.timeoutTask?.cancel()
        state.timeoutTask = nil
        if releaseThread { self.releaseThread(for: state) }
        if let continuation = state.continuation {
            state.continuation = nil
            remove(state)
            continuation.resume(with: result)
        } else {
            state.completedResult = result
        }
    }

    private func discard(_ state: TranslationState, releaseThread: Bool) {
        guard translations[state.identifier] === state else { return }
        state.timeoutTask?.cancel()
        state.timeoutTask = nil
        if releaseThread { self.releaseThread(for: state) }
        remove(state)
    }

    private func releaseThread(for state: TranslationState) {
        guard !state.threadReleased, let session,
              session.identifier == state.sessionIdentifier,
              let threadID = state.threadID
        else { return }
        state.threadReleased = true
        let method = session.runtime.release == .modern ? "thread/delete" : "thread/unsubscribe"
        sendWithoutWaiting(session: session, method: method, params: ["threadId": threadID])
    }

    private func remove(_ state: TranslationState) {
        if let threadID = state.threadID { requestByThread.removeValue(forKey: threadID) }
        translations.removeValue(forKey: state.identifier)
        scheduleIdleShutdown()
    }

    private func stopSession(error: Error) {
        guard let session else { return }
        failSession(session, error: error, terminate: true)
    }

    private func failSession(_ failedSession: Session, error: Error, terminate: Bool) {
        guard session === failedSession else { return }
        session = nil
        cachedRuntime = nil
        idleTask?.cancel()
        idleTask = nil

        failedSession.messages.continuation.finish()
        failedSession.messageTask?.cancel()
        failedSession.messageTask = nil
        let pending = Array(pendingResponses.filter { $0.value.sessionIdentifier == failedSession.identifier })
        for (identifier, response) in pending {
            pendingResponses.removeValue(forKey: identifier)
            response.timeoutTask.cancel()
            response.continuation.resume(throwing: error)
        }
        let readiness = failedSession.readiness
        failedSession.readiness.removeAll()
        readiness.forEach { $0.resume(throwing: error) }
        let active = Array(translations.values.filter { $0.sessionIdentifier == failedSession.identifier })
        for state in active {
            finish(state, result: .failure(error), releaseThread: false)
        }
        if terminate { failedSession.process.terminate() }
    }

    private func processTerminated(_ identifier: UUID, stderr _: Data) {
        guard let session, session.process.identifier == identifier else { return }
        failSession(session, error: CodexManagedError.invalidResponse, terminate: false)
    }

    private func scheduleIdleShutdown() {
        guard translations.isEmpty, session != nil || cachedRuntime != nil else { return }
        idleTask?.cancel()
        idleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.idleTimeout))
            guard !Task.isCancelled else { return }
            await self?.stopIfIdle()
        }
    }

    private func stopIfIdle() {
        guard translations.isEmpty else { return }
        cachedRuntime = nil
        stopSession(error: CancellationError())
    }

    private func threadParameters(model: String, runtime: CodexManagedRuntime) -> [String: Any] {
        [
            "model": model,
            "modelProvider": Self.providerID,
            "cwd": runtime.workingDirectory.path,
            "approvalPolicy": "never",
            "sandbox": "read-only",
            "developerInstructions": CodexManagedRuntime.translationInstructions,
            "ephemeral": true,
            "serviceName": "easydict",
        ]
    }

    private func validate(item: [String: Any]) -> Bool {
        guard let type = item["type"] as? String else { return false }
        return Self.allowedItemTypes.contains(type)
    }

    private func tokenUsage(from params: [String: Any], durationMs: Int) -> CodexTokenUsage? {
        guard let tokenUsage = params["tokenUsage"] as? [String: Any],
              let last = tokenUsage["last"] as? [String: Any]
        else { return nil }
        return CodexTokenUsage(
            inputTokens: (last["inputTokens"] as? NSNumber)?.intValue ?? 0,
            cachedInputTokens: (last["cachedInputTokens"] as? NSNumber)?.intValue ?? 0,
            outputTokens: (last["outputTokens"] as? NSNumber)?.intValue ?? 0,
            reasoningOutputTokens: (last["reasoningOutputTokens"] as? NSNumber)?.intValue ?? 0,
            durationMs: durationMs
        )
    }

    private func elapsedMilliseconds(_ state: TranslationState) -> Int {
        Int((ProcessInfo.processInfo.systemUptime - state.started) * 1000)
    }

    private func runtimeMatches(_ lhs: CodexManagedRuntime, _ rhs: CodexManagedRuntime) -> Bool {
        lhs.release == rhs.release
            && lhs.executable == rhs.executable
            && lhs.codexHome == rhs.codexHome
            && lhs.workingDirectory == rhs.workingDirectory
            && lhs.catalogURL == rhs.catalogURL
    }
}
