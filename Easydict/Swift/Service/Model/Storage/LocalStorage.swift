//
//  LocalStorage.swift
//  Easydict
//
//  Created by tisfeng on 2022/11/22.
//

import Foundation

// MARK: - LocalStorage

/// Local persistence layer for service metadata and usage stats.
@objc(EZLocalStorage)
@objcMembers
final class LocalStorage: NSObject {
    // MARK: Lifecycle

    private override init() {
        super.init()
        setup()
    }

    // MARK: Internal

    // MARK: Public API

    /// Disabled app trigger configurations for select-text.
    var selectTextTypeAppModelList: [AppTriggerConfig] {
        get {
            let storedArray = userDefaults.array(forKey: Constants.appModelTriggerListKey) as? [NSDictionary]
            let appModels = AppTriggerConfig.appModels(from: storedArray ?? [])

            if storedArray == nil {
                let keychainApp = AppTriggerConfig(appBundleID: "com.apple.keychainaccess", triggerType: [])
                return [keychainApp]
            }

            return appModels
        }
        set {
            let dictArray = AppTriggerConfig.dictionaryArray(from: newValue)
            userDefaults.set(dictArray, forKey: Constants.appModelTriggerListKey)
        }
    }

    /// Total query character count.

    var queryCharacterCount: Int {
        get { userDefaults.integer(forKey: Constants.queryCharacterCountKey) }
        set { userDefaults.set(newValue, forKey: Constants.queryCharacterCountKey) }
    }

    /// Total query count.

    var queryCount: Int {
        get { userDefaults.integer(forKey: Constants.queryCountKey) }
        set { userDefaults.set(newValue, forKey: Constants.queryCountKey) }
    }

    // MARK: Singleton

    /// Shared storage instance matching the Objective-C API.
    @objc(shared)
    static func shared() -> LocalStorage {
        if let instance = sharedInstance {
            return instance
        }
        let instance = LocalStorage()
        sharedInstance = instance
        return instance
    }

    /// Destroys the shared storage instance (used for testing or hard resets).
    @objc(destroySharedInstance)
    static func destroySharedInstance() {
        sharedInstance = nil
    }

    /// Returns all service type identifiers for the given window.
    /// - Parameter windowType: Window type to query.
    /// - Returns: Ordered service type identifiers.
    @objc(allServiceTypes:)
    func allServiceTypes(_ windowType: EZWindowType) -> [String] {
        let allServiceTypesKey = serviceTypesKey(of: windowType)
        let allServiceTypes = QueryServiceFactory.shared.allServiceTypeIDs

        guard var storedTypes = userDefaults.array(forKey: allServiceTypesKey) as? [String] else {
            userDefaults.set(allServiceTypes, forKey: allServiceTypesKey)
            return allServiceTypes
        }

        for type in allServiceTypes where !storedTypes.contains(type) {
            storedTypes.append(type)
        }
        userDefaults.set(storedTypes, forKey: allServiceTypesKey)
        return storedTypes
    }

    /// Persists ordered service type identifiers for the given window.
    /// - Parameters:
    ///   - allServiceTypes: Ordered service type identifiers.
    ///   - windowType: Target window type.
    @objc(setAllServiceTypes:windowType:)
    func setAllServiceTypes(_ allServiceTypes: [String], windowType: EZWindowType) {
        let allServiceTypesKey = serviceTypesKey(of: windowType)
        userDefaults.set(allServiceTypes, forKey: allServiceTypesKey)
    }

    /// Returns configured services for the given window with persisted flags applied.
    /// - Parameter windowType: Target window type.
    /// - Returns: Service instances with persisted state applied.
    @objc(allServices:)
    func allServices(_ windowType: EZWindowType) -> [QueryService] {
        let services = QueryServiceFactory.shared.services(fromTypes: allServiceTypes(windowType))
        services.forEach { updateServiceInfo($0, windowType: windowType) }
        return services
    }

    /// Returns a service instance with persisted flags applied.
    /// - Parameters:
    ///   - serviceTypeId: Service type identifier, possibly containing a UUID suffix.
    ///   - windowType: Target window type.
    /// - Returns: Configured service instance.
    @objc(service:windowType:)
    func service(_ serviceTypeId: String, windowType: EZWindowType) -> QueryService {
        guard let service = QueryServiceFactory.shared.service(withTypeId: serviceTypeId) else {
            fatalError("Unsupported service type: \(serviceTypeId)")
        }
        updateServiceInfo(service, windowType: windowType)
        return service
    }

    /// Fetches persisted service info for a service type and id.
    /// - Parameters:
    ///   - type: Service type identifier.
    ///   - serviceId: Unique service identifier.
    ///   - windowType: Target window type.
    /// - Returns: Persisted service info when available.
    @objc(serviceInfoWithType:serviceId:windowType:)
    func serviceInfo(
        withType type: ServiceType,
        serviceId: String,
        windowType: EZWindowType
    )
        -> QueryServiceConfiguration? {
        guard let data = storedServiceInfoData(type: type, serviceId: serviceId, windowType: windowType) else {
            return nil
        }

        if let info = try? decoder.decode(QueryServiceConfiguration.self, from: data) {
            return normalized(info, fallbackType: type, serviceId: serviceId, windowType: windowType)
        }

        if let legacyInfo = decodeLegacyServiceInfo(
            from: data,
            fallbackType: type,
            serviceId: serviceId,
            windowType: windowType
        ) {
            return legacyInfo
        }

        return nil
    }

    /// Persists a service info record.
    /// - Parameters:
    ///   - serviceInfo: Service info to persist.
    ///   - windowType: Target window type.
    @objc(setServiceInfo:windowType:)
    func setServiceInfo(_ serviceInfo: QueryServiceConfiguration, windowType: EZWindowType) {
        let normalizedInfo = normalized(
            serviceInfo,
            fallbackType: serviceInfo.type,
            serviceId: serviceInfo.uuid,
            windowType: windowType
        )

        guard let data = try? encoder.encode(normalizedInfo) else {
            return
        }

        let serviceInfoKey = key(
            forServiceType: normalizedInfo.type,
            serviceId: normalizedInfo.uuid,
            windowType: windowType
        )
        userDefaults.set(data, forKey: serviceInfoKey)
    }

    /// Persists a service's current state.
    /// - Parameters:
    ///   - service: Service whose state should be saved.
    ///   - windowType: Target window type.
    @objc(setService:windowType:)
    func setService(_ service: QueryService, windowType: EZWindowType) {
        let serviceInfo = QueryServiceConfiguration.serviceInfo(with: service)
        setServiceInfo(serviceInfo, windowType: windowType)
    }

    /// Updates query enablement for a service.
    /// - Parameters:
    ///   - enabledQuery: Whether the service is allowed to query.
    ///   - serviceType: Service type identifier.
    ///   - serviceId: Unique service identifier.
    ///   - windowType: Target window type.
    @objc(setEnabledQuery:serviceType:serviceId:windowType:)
    func setEnabledQuery(_ enabledQuery: Bool, serviceType: ServiceType, serviceId: String, windowType: EZWindowType) {
        let info = serviceInfo(withType: serviceType, serviceId: serviceId, windowType: windowType) ??
            QueryServiceConfiguration(
                uuid: serviceId,
                type: serviceType,
                enabled: true,
                enabledQuery: enabledQuery,
                windowType: windowType
            )

        info.enabledQuery = enabledQuery
        setServiceInfo(info, windowType: windowType)
    }

    /// Increases total query counts using the provided query text length.
    /// - Parameter queryText: Text used for the query.
    @objc(increaseQueryCount:)
    func increaseQueryCount(_ queryText: String) {
        let currentCount = queryCount
        let currentLevel = queryLevel(for: currentCount)
        let newCount = currentCount + 1
        let newLevel = queryLevel(for: newCount)

        if currentCount == 0 || newLevel != currentLevel {
            let levelTitle = queryLevelTitle(newLevel, chineseFlag: true)
            logInfo("new level: \(levelTitle)")

            let dict: [String: String] = [
                "count": "\(newCount)",
                "level": "\(newLevel)",
                "title": levelTitle,
            ]
            AnalyticsService.logEvent(withName: "query_count", parameters: dict)
        }

        queryCount = newCount
        queryCharacterCount += queryText.count
    }

    /// Updates per-service query statistics.
    /// - Parameter service: Service being queried.
    @objc(increaseQueryService:)
    func increaseQueryService(_ service: QueryService) {
        let serviceType = service.serviceType()
        let record = record(with: serviceType)
        let queryLength = service.queryModel.queryText.count
        record.queryCount += 1
        record.queryCharacterCount += queryLength
        setQueryServiceRecord(record, serviceType: serviceType)

        AnalyticsService.logQueryService(service)
    }

    /// Checks whether a service has free quota left for the current user.
    /// - Parameter service: Service being queried.
    /// - Returns: `true` when the free quota is not exceeded.
    @objc(hasFreeQuotaLeft:)
    func hasFreeQuotaLeft(_ service: QueryService) -> Bool {
        let record = record(with: service.serviceType())
        let totalFreeCharacters = Double(service.totalFreeQueryCharacterCount()) * 0.9 /
            Double(Constants.totalUserCount)
        return Double(record.queryCharacterCount) < totalFreeCharacters
    }

    /// Whether the user is considered new.

    func isNewUser() -> Bool {
        queryCount < 100
    }

    // MARK: Private

    private static var sharedInstance: LocalStorage?

    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Raw dictionary backing service query statistics.
    private var queryServiceRecordDict: [String: [String: Any]] {
        get {
            userDefaults.dictionary(forKey: Constants.queryServiceRecordKey) as? [String: [String: Any]] ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: Constants.queryServiceRecordKey)
        }
    }

    /// Ensures all known services have stored defaults for each window type.
    private func setup() {
        let allWindowTypes: [EZWindowType] = [.mini, .fixed, .main]

        for windowType in allWindowTypes {
            let serviceTypeIds = allServiceTypes(windowType)

            for serviceTypeId in serviceTypeIds {
                let components = serviceTypeId.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
                let rawType = String(components.first ?? Substring(serviceTypeId))
                let uuid = components.count > 1 ? String(components[1]) : ""
                let baseType = ServiceType(rawValue: rawType)

                if serviceInfo(withType: baseType, serviceId: uuid, windowType: windowType) == nil {
                    let serviceInfo = QueryServiceConfiguration(
                        uuid: uuid,
                        type: baseType,
                        enabled: true,
                        enabledQuery: queryCount == 0,
                        windowType: windowType
                    )

                    let defaultEnabledServices: [ServiceType] = [
                        .youdao,
                        .deepL,
                        .builtInAI,
                    ]

                    serviceInfo.enabled = defaultEnabledServices.contains { $0.rawValue == rawType }
                    setServiceInfo(serviceInfo, windowType: windowType)
                }
            }
        }
    }

    /// Applies persisted flags to a live service instance.
    /// - Parameters:
    ///   - service: Service to update.
    ///   - windowType: Window the service belongs to.
    private func updateServiceInfo(_ service: QueryService, windowType: EZWindowType) {
        let info = serviceInfo(withType: service.serviceType(), serviceId: service.uuid, windowType: windowType)
        service.enabled = info?.enabled ?? true
        service.enabledQuery = info?.enabledQuery ?? true
        service.windowType = windowType
        service.uuid = info?.uuid ?? service.uuid
    }

    /// Builds the UserDefaults key for a service instance.
    /// - Parameters:
    ///   - serviceType: Base service type.
    ///   - serviceId: Unique service identifier.
    ///   - windowType: Window scope.
    /// - Returns: Namespaced storage key.
    private func key(forServiceType serviceType: ServiceType, serviceId: String, windowType: EZWindowType) -> String {
        let baseType = baseServiceType(from: serviceType).rawValue
        if serviceId.isEmpty {
            return "\(Constants.serviceInfoStorageKey)-\(baseType)-\(windowType.rawValue)"
        }
        return "\(Constants.serviceInfoStorageKey)-\(baseType)-\(serviceId)-\(windowType.rawValue)"
    }

    /// Builds the UserDefaults key for persisted service order.
    /// - Parameter windowType: Window scope.
    /// - Returns: Namespaced storage key.
    private func serviceTypesKey(of windowType: EZWindowType) -> String {
        "\(Constants.allServiceTypesKey)-\(windowType.rawValue)"
    }

    /// Reads or creates a per-service query usage record.
    /// - Parameter serviceType: Service type to query.
    /// - Returns: Usage record with counts.
    private func record(with serviceType: ServiceType) -> QueryServiceRecord {
        let dict = queryServiceRecordDict
        if let recordDict = dict[serviceType.rawValue],
           let queryCount = (recordDict["queryCount"] as? NSNumber)?.intValue ?? recordDict["queryCount"] as? Int,
           let queryCharacterCount = (recordDict["queryCharacterCount"] as? NSNumber)?
           .intValue ?? recordDict["queryCharacterCount"] as? Int {
            return QueryServiceRecord(
                serviceType: serviceType,
                queryCount: queryCount,
                queryCharacterCount: queryCharacterCount
            )
        }

        let record = QueryServiceRecord(serviceType: serviceType, queryCount: 0, queryCharacterCount: 0)
        setQueryServiceRecord(record, serviceType: serviceType)
        return record
    }

    /// Persists a per-service query usage record.
    /// - Parameters:
    ///   - record: Usage record to store.
    ///   - serviceType: Associated service type.
    private func setQueryServiceRecord(_ record: QueryServiceRecord, serviceType: ServiceType) {
        var dict = queryServiceRecordDict
        dict[serviceType.rawValue] = [
            "serviceType": record.serviceType.rawValue,
            "queryCount": record.queryCount,
            "queryCharacterCount": record.queryCharacterCount,
        ]
        queryServiceRecordDict = dict
    }

    /// Calculates a query level bucket for a count.
    /// - Parameter count: Total query count.
    /// - Returns: Level index.
    private func queryLevel(for count: Int) -> Int {
        switch count {
        case ..<10: return 1
        case ..<100: return 2
        case ..<500: return 3
        case ..<2000: return 4
        case ..<5000: return 5
        case ..<10000: return 6
        case ..<20000: return 7
        case ..<50000: return 8
        case ..<100000: return 9
        default: return 10
        }
    }

    /// Returns a localized level title.
    /// - Parameters:
    ///   - level: Level index.
    ///   - chineseFlag: Whether Chinese labels should be used.
    /// - Returns: Level title.
    private func queryLevelTitle(_ level: Int, chineseFlag: Bool) -> String {
        let titles = ["黑铁", "青铜", "白银", "黄金", "铂金", "钻石", "大师", "宗师", "王者", "传奇"]
        let enTitles = [
            "Iron",
            "Bronze",
            "Silver",
            "Gold",
            "Platinum",
            "Diamond",
            "Master",
            "Grandmaster",
            "King",
            "Legend",
        ]

        let clampedLevel = max(1, min(level, titles.count))
        return chineseFlag ? titles[clampedLevel - 1] : enTitles[clampedLevel - 1]
    }

    /// Retrieves persisted service info data with backward-compatible keys.
    /// - Parameters:
    ///   - type: Service type identifier.
    ///   - serviceId: Service UUID.
    ///   - windowType: Window scope.
    /// - Returns: Stored data when available.
    private func storedServiceInfoData(type: ServiceType, serviceId: String, windowType: EZWindowType) -> Data? {
        let baseKey = key(forServiceType: type, serviceId: serviceId, windowType: windowType)
        if let data = userDefaults.data(forKey: baseKey) {
            return data
        }

        guard !serviceId.isEmpty else {
            return nil
        }

        let uniqueType = ServiceType(rawValue: "\(type.rawValue)#\(serviceId)")
        let uniqueKey = key(forServiceType: uniqueType, serviceId: serviceId, windowType: windowType)
        return userDefaults.data(forKey: uniqueKey)
    }

    /// Attempts to decode legacy JSON payloads saved by MJExtension.
    /// - Parameters:
    ///   - data: Raw JSON data.
    ///   - fallbackType: Service type to use when missing.
    ///   - serviceId: Service UUID.
    ///   - windowType: Window scope.
    /// - Returns: Normalized service info when decoding succeeds.
    private func decodeLegacyServiceInfo(
        from data: Data,
        fallbackType: ServiceType,
        serviceId: String,
        windowType: EZWindowType
    )
        -> QueryServiceConfiguration? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let typeRaw = jsonObject["type"] as? String ?? fallbackType.rawValue
        let legacyUUID = jsonObject["uuid"] as? String ?? serviceId
        let enabled = jsonObject["enabled"] as? Bool ?? true
        let enabledQuery = jsonObject["enabledQuery"] as? Bool ?? true
        let windowValue = jsonObject["windowType"] as? Int ?? windowType.rawValue

        let info = QueryServiceConfiguration(
            uuid: legacyUUID,
            type: ServiceType(rawValue: typeRaw),
            enabled: enabled,
            enabledQuery: enabledQuery,
            windowType: EZWindowType(rawValue: windowValue) ?? windowType
        )

        return normalized(info, fallbackType: fallbackType, serviceId: serviceId, windowType: windowType)
    }

    /// Normalizes service info to ensure base type, window type, and UUID are present.
    /// - Parameters:
    ///   - info: Raw service info object.
    ///   - fallbackType: Service type to apply when missing.
    ///   - serviceId: Service UUID to apply when missing.
    ///   - windowType: Window scope to apply.
    /// - Returns: Normalized service info.
    private func normalized(
        _ info: QueryServiceConfiguration,
        fallbackType: ServiceType,
        serviceId: String,
        windowType: EZWindowType
    )
        -> QueryServiceConfiguration {
        let baseType = baseServiceType(from: info.type)
        let normalizedUUID = info.uuid.isEmpty ? serviceId : info.uuid

        let normalizedInfo = QueryServiceConfiguration(
            uuid: normalizedUUID,
            type: baseType,
            enabled: info.enabled,
            enabledQuery: info.enabledQuery,
            windowType: windowType
        )

        return normalizedInfo
    }

    /// Returns a service type without any duplicated-instance suffix.
    /// - Parameter serviceType: Service type that may contain a `#uuid` suffix.
    /// - Returns: Base service type.
    private func baseServiceType(from serviceType: ServiceType) -> ServiceType {
        guard let separatorIndex = serviceType.rawValue.firstIndex(of: "#") else {
            return serviceType
        }
        let rawValue = String(serviceType.rawValue[..<separatorIndex])
        return ServiceType(rawValue: rawValue)
    }
}

// MARK: - Constants

private enum Constants {
    static let serviceInfoStorageKey = "kServiceInfoStorageKey"
    static let allServiceTypesKey = "kAllServiceTypesKey"
    static let queryCountKey = "kQueryCountKey"
    static let queryCharacterCountKey = "kQueryCharacterCountKey"
    static let appModelTriggerListKey = "kAppModelTriggerListKey"
    static let queryServiceRecordKey = "kQueryServiceRecordKey"
    static let totalUserCount = 1000
}
