//
//  OrcaRouterServiceTests.swift
//  EasydictTests
//
//  Created by jinhao.song on 2026/8/23.
//  Copyright © 2026 izual. All rights reserved.
//

import Testing

@testable import Easydict

@Suite("OrcaRouter Service", .tags(.unit))
struct OrcaRouterServiceTests {
    // MARK: Internal

    @Test("Factory registers OrcaRouter with correct metadata")
    func factoryRegistersOrcaRouter() throws {
        let metadata = try #require(
            QueryServiceFactory.shared.metadata(withTypeId: ServiceType.orcaRouter.rawValue)
        )
        #expect(metadata.serviceType == .orcaRouter)
        #expect(metadata.apiKeyRequirement == .userProvided)
        #expect(metadata.isStream)
        #expect(!metadata.allowsMultipleInstances)
    }

    @Test("OrcaRouter service defaults point at the OrcaRouter gateway")
    func serviceDefaults() throws {
        let service = try #require(
            QueryServiceFactory.shared.service(withTypeId: ServiceType.orcaRouter.rawValue)
        ) as? OrcaRouterService

        #expect(service?.link() == "https://www.orcarouter.ai")
        #expect(service?.defaultEndpoint == "https://api.orcarouter.ai/v1/chat/completions")
        #expect(service?.defaultModels == OrcaRouterModel.allCases.map(\.rawValue))
        #expect(service?.defaultModel == "orcarouter/auto")
    }
}
