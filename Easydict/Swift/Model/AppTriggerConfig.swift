//
//  AppTriggerConfig.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/16.
//  Copyright © 2025 izual. All rights reserved.
//

import Foundation

// MARK: - AppTriggerConfig

/// Represents an app entry and its trigger configuration for text selection handling.
@objcMembers
final class AppTriggerConfig: NSObject, NSSecureCoding {
    // MARK: Lifecycle

    /// Creates an empty app model with no triggers.
    override init() {
        self.appBundleID = ""
        self.triggerType = []
        super.init()
    }

    /// Creates an app model with a bundle identifier and trigger configuration.
    /// - Parameters:
    ///   - appBundleID: Bundle identifier for the app.
    ///   - triggerType: Configured trigger options.
    init(appBundleID: String, triggerType: EZTriggerType) {
        self.appBundleID = appBundleID
        self.triggerType = triggerType
        super.init()
    }

    /// Decodes a persisted app model instance.
    /// - Parameter coder: Coder used to decode stored values.
    required init?(coder: NSCoder) {
        guard let bundleID = coder.decodeObject(of: NSString.self, forKey: CodingKeys.appBundleID.rawValue) as String?
        else {
            return nil
        }
        let rawValue = coder.decodeObject(of: NSNumber.self, forKey: CodingKeys.triggerType.rawValue)?.uintValue ?? 0
        self.appBundleID = bundleID
        self.triggerType = EZTriggerType(rawValue: rawValue)
        super.init()
    }

    // MARK: Internal

    /// Indicates secure coding support for archiving.
    static var supportsSecureCoding: Bool { true }

    /// Hash based on bundle identifier to align with equality.
    override var hash: Int {
        appBundleID.hashValue
    }

    /// Bundle identifier of the target app.
    var appBundleID: String

    /// Trigger configuration for select-text actions.
    var triggerType: EZTriggerType

    /// Compares two app models by bundle identifier.
    /// - Parameter object: The object to compare with.
    /// - Returns: `true` when bundle identifiers match.
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AppTriggerConfig else { return false }
        return appBundleID == other.appBundleID
    }

    /// Encodes the app model for persistence.
    /// - Parameter coder: Coder used to encode values.
    func encode(with coder: NSCoder) {
        coder.encode(appBundleID, forKey: CodingKeys.appBundleID.rawValue)
        coder.encode(NSNumber(value: triggerType.rawValue), forKey: CodingKeys.triggerType.rawValue)
    }
}

// MARK: - Dictionary Helpers

extension AppTriggerConfig {
    /// Converts a model to a dictionary for persistence.
    /// - Parameter appModel: The model to convert.
    /// - Returns: Dictionary containing bundle identifier and trigger raw value.
    @objc(dictionaryFromAppModel:)
    static func dictionary(from appModel: AppTriggerConfig) -> NSDictionary {
        [
            CodingKeys.appBundleID.rawValue: appModel.appBundleID,
            CodingKeys.triggerType.rawValue: NSNumber(value: appModel.triggerType.rawValue),
        ]
    }

    /// Creates a model from a persisted dictionary.
    /// - Parameter dictionary: Dictionary containing model fields.
    /// - Returns: Parsed `AppModel` instance when bundle identifier exists.
    @objc(appModelFromDictionary:)
    static func appModel(from dictionary: NSDictionary) -> AppTriggerConfig? {
        guard let bundleID = dictionary[CodingKeys.appBundleID.rawValue] as? String else {
            return nil
        }
        let rawValue = (dictionary[CodingKeys.triggerType.rawValue] as? NSNumber)?.uintValue ?? 0
        return AppTriggerConfig(appBundleID: bundleID, triggerType: EZTriggerType(rawValue: rawValue))
    }

    /// Converts an array of models to dictionaries for user defaults storage.
    /// - Parameter appModels: Models to persist.
    /// - Returns: Array of dictionaries ready for storage.
    @objc(dictionaryArrayFromAppModels:)
    static func dictionaryArray(from appModels: [AppTriggerConfig]) -> [NSDictionary] {
        appModels.map { dictionary(from: $0) }
    }

    /// Restores models from persisted dictionaries.
    /// - Parameter dictionaryArray: Dictionaries loaded from storage.
    /// - Returns: Array of parsed models.
    @objc(appModelsFromDictionaryArray:)
    static func appModels(from dictionaryArray: [NSDictionary]) -> [AppTriggerConfig] {
        dictionaryArray.compactMap { appModel(from: $0) }
    }
}

// MARK: AppTriggerConfig.CodingKeys

extension AppTriggerConfig {
    fileprivate enum CodingKeys: String {
        case appBundleID
        case triggerType
    }
}
