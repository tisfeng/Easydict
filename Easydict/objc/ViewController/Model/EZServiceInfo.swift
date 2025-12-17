//
//  EZServiceInfo.swift
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//

import Foundation

/// Stores persisted metadata for a query service, such as enablement and target window type.
@objc(EZServiceInfo)
@objcMembers
final class EZServiceInfo: NSObject, Codable {
    // MARK: Lifecycle

    /// Creates a new service info instance.
    init(
        uuid: String = "",
        type: ServiceType,
        enabled: Bool = true,
        enabledQuery: Bool = true,
        windowType: EZWindowType = .main
    ) {
        self.uuid = uuid
        self.type = type
        self.enabled = enabled
        self.enabledQuery = enabledQuery
        self.windowType = windowType
        super.init()
    }

    /// Decodes a service info instance from persisted data.
    /// - Parameter decoder: Decoder providing stored values.
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedType = try container.decodeIfPresent(String.self, forKey: .type) ?? ServiceType.appleDictionary
            .rawValue
        let decodedUUID = try container.decodeIfPresent(String.self, forKey: .uuid) ?? ""
        let windowTypeValue = try container.decodeIfPresent(Int.self, forKey: .windowType) ?? EZWindowType.main.rawValue

        self.uuid = decodedUUID
        self.type = ServiceType(rawValue: decodedType)
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        self.enabledQuery = try container.decodeIfPresent(Bool.self, forKey: .enabledQuery) ?? true
        self.windowType = EZWindowType(rawValue: windowTypeValue) ?? .main
        super.init()
    }

    // MARK: Internal

    /// Identifier for distinguishing duplicated services.
    var uuid: String

    /// Service type identifier (may include legacy `#uuid` suffix in stored data).
    var type: ServiceType

    /// Whether the service is enabled on the settings page.
    var enabled: Bool

    /// Whether the service is allowed to execute queries.
    var enabledQuery: Bool

    /// Target window type for this service instance.
    var windowType: EZWindowType

    /// Builds a service info from a concrete query service.
    /// - Parameter service: Source query service.
    /// - Returns: Populated service info instance.
    @objc(serviceInfoWithService:)
    static func serviceInfo(with service: QueryService) -> EZServiceInfo {
        EZServiceInfo(
            uuid: service.uuid,
            type: service.serviceType(),
            enabled: service.enabled,
            enabledQuery: service.enabledQuery,
            windowType: service.windowType
        )
    }

    /// Encodes the service info for persistence.
    /// - Parameter encoder: Encoder used for serialization.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(enabledQuery, forKey: .enabledQuery)
        try container.encode(windowType.rawValue, forKey: .windowType)
    }

    // MARK: Private

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case uuid
        case type
        case enabled
        case enabledQuery
        case windowType
    }
}
