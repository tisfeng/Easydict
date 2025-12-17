//
//  QueryServiceFactory.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/16.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

/// A registry that maps `ServiceType` identifiers to their corresponding `QueryService` subclasses.
///
/// This class mirrors the legacy Objective-C `EZServiceTypes` API and stays accessible from both Objective-C and Swift.
@objcMembers
final class QueryServiceFactory: NSObject {
    // MARK: Internal

    /// Shared singleton instance.
    static let shared = QueryServiceFactory()

    /// Ordered list of all supported service types.
    var allServiceTypes: [ServiceType] {
        guard let keys = serviceDictionary.sortedKeys() as? [String] else {
            return []
        }
        return keys.compactMap(ServiceType.init(rawValue:))
    }

    /// Ordered list of all supported service type identifiers as raw strings.
    var allServiceTypeIDs: [String] {
        allServiceTypes.map(\.rawValue)
    }

    /// Creates a `QueryService` instance for the given type identifier.
    ///
    /// - Parameter typeIdIfHave: A service type identifier, optionally containing a UUID suffix separated by `#`.
    /// - Returns: A configured `QueryService` instance if the type is supported; otherwise, `nil`.
    func service(withTypeId typeIdIfHave: String) -> QueryService? {
        let components = typeIdIfHave.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let serviceTypeString = String(components.first ?? Substring(typeIdIfHave))
        let uuid = components.count > 1 ? String(components[1]) : ""

        guard let serviceClass = serviceDictionary.object(forKey: serviceTypeString) as? QueryService.Type else {
            return nil
        }

        let service = serviceClass.init()
        service.uuid = uuid
        return service
    }

    /// Creates `QueryService` instances from a list of service type identifiers.
    ///
    /// - Parameter types: An array of service type identifiers.
    /// - Returns: A list of instantiated services. Unsupported types are ignored.
    func services(fromTypes types: [String]) -> [QueryService] {
        types.compactMap { service(withTypeId: $0) }
    }

    // MARK: Private

    private lazy var serviceDictionary: MMOrderedDictionary = {
        let dictionary = MMOrderedDictionary()
        serviceTypeMappings.forEach { mapping in
            dictionary.setObject(mapping.serviceClass, forKey: mapping.serviceType.rawValue)
        }
        return dictionary
    }()

    private let serviceTypeMappings: [(serviceType: ServiceType, serviceClass: QueryService.Type)] = [
        (.appleDictionary, AppleDictionary.self),
        (.youdao, YoudaoService.self),
        (.openAI, OpenAIService.self),
        (.deepSeek, DeepSeekService.self),
        (.groq, GroqService.self),
        (.zhipu, ZhipuService.self),
        (.gitHub, GitHubService.self),
        (.builtInAI, BuiltInAIService.self),
        (.gemini, GeminiService.self),
        (.ollama, OllamaService.self),
        (.polishing, PolishingService.self),
        (.summary, SummaryService.self),
        (.customOpenAI, CustomOpenAIService.self),
        (.deepL, DeepLService.self),
        (.google, GoogleService.self),
        (.apple, AppleService.self),
        (.baidu, EZBaiduTranslate.self),
        (.bing, BingService.self),
        (.volcano, VolcanoService.self),
        (.niuTrans, NiuTransService.self),
        (.caiyun, CaiyunService.self),
        (.tencent, TencentService.self),
        (.alibaba, AliService.self),
        (.doubao, DoubaoService.self),
    ]
}
