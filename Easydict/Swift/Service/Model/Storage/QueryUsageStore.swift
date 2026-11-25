//
//  QueryUsageStore.swift
//  Easydict
//

import Foundation

// MARK: - QueryUsageStore

/// Persists query counts and per-service usage in the existing defaults format.
final class QueryUsageStore {
    // MARK: Lifecycle

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    // MARK: Internal

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

    /// Increases total query counts using the provided query text length.
    /// - Parameter queryText: Text used for the query.
    func increaseQueryCount(_ queryText: String) {
        let currentCount = queryCount
        let currentLevel = queryLevel(for: currentCount)
        let newCount = currentCount + 1
        let newLevel = queryLevel(for: newCount)

        if currentCount == 0 || newLevel != currentLevel {
            let levelTitle = queryLevelTitle(newLevel)
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
    func hasFreeQuotaLeft(_ service: QueryService) -> Bool {
        let record = record(with: service.serviceType())
        let totalFreeCharacters = Double(service.totalFreeQueryCharacterCount()) * 0.9 /
            Double(Constants.totalUserCount)
        return Double(record.queryCharacterCount) < totalFreeCharacters
    }

    func isNewUser() -> Bool {
        queryCount < 100
    }

    // MARK: Private

    private let userDefaults: UserDefaults

    /// Raw dictionary backing service query statistics.
    private var queryServiceRecordDict: [String: [String: Any]] {
        get {
            userDefaults.dictionary(forKey: Constants.queryServiceRecordKey) as? [String: [String: Any]] ?? [:]
        }
        set {
            userDefaults.set(newValue, forKey: Constants.queryServiceRecordKey)
        }
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

    /// Returns the title used in query count logs and analytics.
    private func queryLevelTitle(_ level: Int) -> String {
        let titles = ["黑铁", "青铜", "白银", "黄金", "铂金", "钻石", "大师", "宗师", "王者", "传奇"]
        let clampedLevel = max(1, min(level, titles.count))
        return titles[clampedLevel - 1]
    }
}

// MARK: - Constants

private enum Constants {
    static let queryCountKey = "kQueryCountKey"
    static let queryCharacterCountKey = "kQueryCharacterCountKey"
    static let queryServiceRecordKey = "kQueryServiceRecordKey"
    static let totalUserCount = 1000
}
