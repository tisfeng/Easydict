//
//  QianfanServiceTests.swift
//  EasydictTests
//
//  Copyright © 2026 izual. All rights reserved.
//

import Foundation
import Testing

@testable import Easydict

// MARK: - QianfanServiceTests

@Suite("QianfanService", .serialized)
struct QianfanServiceTests {
    @Test("service exposes Baidu Qianfan Chat V2 configuration")
    func serviceContract() {
        let service = QianfanService()

        #expect(service.serviceType() == .qianfan)
        #expect(service.apiKeyRequirement() == .userProvided)
        #expect(service.isStream())
        #expect(service.defaultEndpoint == "https://qianfan.baidubce.com/v2/chat/completions")
        #expect(service.remoteModelsEndpoint == "https://qianfan.baidubce.com/v2/models")
        #expect(service.defaultModel == "ernie-4.5-turbo-128k")
        #expect(service.defaultModels.contains("ernie-5.1"))
        #expect(!service.name().isEmpty)
    }

    @Test("service is registered in the query service factory")
    func factoryRegistration() {
        let service = QueryServiceFactory.shared.service(
            withTypeId: ServiceType.qianfan.rawValue
        )

        #expect(service is QianfanService)
    }

    @Test("configured Qianfan API key validates a translation")
    func validatesQianfanTranslation() async {
        let service = QianfanService()
        let result = await service.validate()

        #expect(
            result.error == nil,
            "Qianfan validation failed: \(result.error?.localizedDescription ?? "unknown error")"
        )
        #expect(result.translatedText?.isEmpty == false)
    }
}
