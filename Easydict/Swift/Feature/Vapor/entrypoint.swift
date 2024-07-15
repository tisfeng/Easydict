//
//  vapor.swift
//  Easydict
//
//  Created by tisfeng on 2024/7/15.
//  Copyright © 2024 izual. All rights reserved.
//

import Logging
import NIOCore
import NIOPosix
import Vapor

enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)

        let app = try await Application.make(env)

        // This attempts to install NIO as the Swift Concurrency global executor.
        // You should not call any async functions before this point.
        let executorTakeoverSuccess = NIOSingletons
            .unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        app.logger
            .debug(
                "Running with \(executorTakeoverSuccess ? "SwiftNIO" : "standard") Swift Concurrency default executor"
            )

        do {
            try await configure(app)
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.execute()
        try await app.asyncShutdown()
    }
}
