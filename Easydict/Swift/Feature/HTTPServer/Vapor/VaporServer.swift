//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Logging
import NIOCore
import NIOPosix
import Vapor

// MARK: - HTTPServer

@MainActor
class VaporServer {
    // MARK: Lifecycle

    init() {
        do {
            // Vapor template code https://github.com/vapor/template-bare/blob/main/Sources/App/entrypoint.swift

            self.env = try Environment.detect()
            guard var env else {
                return
            }

            // These code should be run only once.
            try LoggingSystem.bootstrap(from: &env)

            // This attempts to install NIO as the Swift Concurrency global executor.
            // You should not call any async functions before this point.
            let executorTakeoverSuccess = NIOSingletons
                .unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
            logInfo(
                "Running with \(executorTakeoverSuccess ? "SwiftNIO" : "standard") Swift Concurrency default executor"
            )
        } catch {
            logError("Failed to detect environment: \(error)")
        }
    }

    // MARK: Internal

    static let shared = VaporServer()

    var app: Vapor.Application?
    var env: Environment?

    var httpPort: Int {
        Int(Defaults[.httpPort]) ?? 8080
    }

    var enableHTTPServer: Bool {
        get { Defaults[.enableHTTPServer] }
        set { Defaults[.enableHTTPServer] = newValue }
    }

    func startServer(isOn: Bool) async {
        logInfo("Start server: \(isOn)")

        if isOn {
            do {
                try await start()
                logInfo("Server started on http://localhost:\(httpPort)")
            } catch {
                enableHTTPServer = false

                logError("Failed to start server: \(error)")
                showAlert(error: error)
            }
        } else {
            await stop()
            logInfo("Server stopped")
        }
    }

    // MARK: Private

    private func start() async throws {
        guard let env else {
            return
        }

        let app = try await Application.make(env)
        self.app = app

        app.http.server.configuration.port = httpPort

        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }

        try await app.execute()
    }

    private func stop() async {
        try? await app?.asyncShutdown()
    }

    // Show alert when error
    private func showAlert(error: Error) {
        let alert = NSAlert()
        alert.messageText = String(localized: "start_server_error \(String(httpPort))")
        alert.informativeText = String(describing: error)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
