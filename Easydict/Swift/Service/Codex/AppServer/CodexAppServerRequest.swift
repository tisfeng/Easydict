//
//  CodexAppServerRequest.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import Foundation

/// Owns one streaming request through either App Server instance.
final class CodexAppServerRequest: @unchecked Sendable {
    // MARK: Internal

    /// Streams one translation through the shared process without sharing thread state.
    func runUsingAppServer(
        prompt: String,
        model: String,
        effort: String?,
        runtime: CodexRuntime?,
        imageURL: String? = nil,
        deltaReceived: @escaping @Sendable (String) -> ()
    ) async throws
        -> CodexAppServer.Response {
        let server = runtime == nil ? CodexAppServer.localCLI : CodexAppServer.managed
        let requestID = try lock.withLock { () -> UUID in
            if cancelled { throw CancellationError() }
            let requestID = UUID()
            appServerRequest = (requestID, server)
            return requestID
        }
        return try await withTaskCancellationHandler {
            do {
                let result = try await server.translate(
                    CodexAppServer.TranslationRequest(
                        identifier: requestID,
                        prompt: prompt,
                        model: model,
                        effort: effort,
                        runtime: runtime,
                        imageURL: imageURL,
                        isCancelled: { [weak self] in self?.isCancelled ?? true },
                        deltaReceived: deltaReceived
                    )
                )
                clearAppServerRequest(requestID)
                return result
            } catch {
                clearAppServerRequest(requestID)
                if runtime == nil, error as? CodexServiceError == .loginRequired {
                    throw CodexCLIError.notLoggedIn
                }
                throw error
            }
        } onCancel: { [weak self] in
            self?.cancelAppServerRequest(requestID)
        }
    }

    func cancel() {
        let request = lock.withLock {
            cancelled = true
            return appServerRequest
        }
        if let request { Task { await request.server.cancel(request.id) } }
    }

    // MARK: Private

    private let lock = NSLock()
    private var cancelled = false
    private var appServerRequest: (id: UUID, server: CodexAppServer)?

    private var isCancelled: Bool { lock.withLock { cancelled } }

    private func clearAppServerRequest(_ requestID: UUID) {
        lock.withLock {
            if appServerRequest?.id == requestID { appServerRequest = nil }
        }
    }

    private func cancelAppServerRequest(_ requestID: UUID) {
        let request = lock.withLock { appServerRequest }
        if let request, request.id == requestID {
            Task { await request.server.cancel(requestID) }
        }
    }
}
