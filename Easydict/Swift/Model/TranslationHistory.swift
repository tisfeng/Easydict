//
//  TranslationHistory.swift
//  Easydict
//
//  Created by Ryan on 2026/01/10.
//  Copyright © 2025 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - TranslationHistoryItem

/// Represents a single translation history item.
public struct TranslationHistoryItem: Codable, Identifiable, Equatable {
    // MARK: Lifecycle

    /// Creates a new translation history item.
    public init(
        queryText: String,
        translatedText: String,
        fromLanguage: Language,
        toLanguage: Language,
        serviceType: String
    ) {
        self.id = UUID().uuidString
        self.queryText = queryText
        self.translatedText = translatedText
        self.fromLanguageRawValue = fromLanguage.rawValue
        self.toLanguageRawValue = toLanguage.rawValue
        self.timestamp = Date()
        self.serviceType = serviceType
    }

    // MARK: Public

    /// Unique identifier for this history item.
    public let id: String

    /// Original query text.
    public let queryText: String

    /// Translated text.
    public let translatedText: String

    /// Timestamp when the translation was performed.
    public let timestamp: Date

    /// Service type used for this translation.
    public let serviceType: String

    /// Source language.
    public var fromLanguage: Language {
        Language(rawValue: fromLanguageRawValue)
    }

    /// Target language.
    public var toLanguage: Language {
        Language(rawValue: toLanguageRawValue)
    }

    // MARK: Internal

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, queryText, translatedText, fromLanguageRawValue, toLanguageRawValue, timestamp, serviceType
    }

    // MARK: Private

    /// Source language (stored as raw value for Codable).
    private let fromLanguageRawValue: String

    /// Target language (stored as raw value for Codable).
    private let toLanguageRawValue: String
}

// MARK: - TranslationHistoryManager

/// Manages translation history storage and retrieval.
@objc(TranslationHistoryManager)
class TranslationHistoryManager: NSObject, ObservableObject {
    // MARK: Lifecycle

    override init() {
        super.init()
        // Load history synchronously on main thread during initialization
        if Thread.isMainThread {
            loadHistory()
        } else {
            DispatchQueue.main.sync {
                loadHistory()
            }
        }
    }

    // MARK: Internal

    /// Shared singleton instance.
    @objc(shared) static let shared = TranslationHistoryManager()

    /// Published history items.
    @Published private(set) var historyItems: [TranslationHistoryItem] = []

    /// Maximum number of history items to store (default: 20, max: 50).
    @Default(.translationHistoryMaxCount) var maxHistoryCount: Int {
        didSet {
            trimHistoryIfNeeded()
        }
    }

    /// Adds a new translation to history.
    /// - Parameters:
    ///   - queryText: Original query text.
    ///   - translatedText: Translated text.
    ///   - fromLanguage: Source language.
    ///   - toLanguage: Target language.
    ///   - serviceType: Service type identifier.
    @MainActor
    func addHistory(
        queryText: String,
        translatedText: String,
        fromLanguage: Language,
        toLanguage: Language,
        serviceType: String
    ) {
        // Skip empty translations
        guard !queryText.isEmpty, !translatedText.isEmpty else { return }

        let item = TranslationHistoryItem(
            queryText: queryText,
            translatedText: translatedText,
            fromLanguage: fromLanguage,
            toLanguage: toLanguage,
            serviceType: serviceType
        )

        // Remove duplicate if same query text exists
        historyItems.removeAll { $0.queryText == queryText && $0.translatedText == translatedText }

        // Add to beginning
        historyItems.insert(item, at: 0)

        trimHistoryIfNeeded()
        saveHistory()
    }

    /// Removes a history item by ID.
    /// - Parameter id: Item identifier.
    @MainActor
    func removeHistory(id: String) {
        historyItems.removeAll { $0.id == id }
        saveHistory()
    }

    /// Clears all translation history.
    @MainActor
    func clearAllHistory() {
        historyItems.removeAll()
        saveHistory()
    }

    // MARK: Private

    private let historyKey = "EZTranslationHistory"

    /// Loads history from UserDefaults.
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([TranslationHistoryItem].self, from: data)
        else {
            historyItems = []
            return
        }
        historyItems = items
        trimHistoryIfNeeded()
    }

    /// Saves history to UserDefaults.
    @MainActor
    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(historyItems) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    /// Trims history to maximum count if needed.
    @MainActor
    private func trimHistoryIfNeeded() {
        let maxCount = min(maxHistoryCount, 50) // Enforce max limit
        if historyItems.count > maxCount {
            historyItems = Array(historyItems.prefix(maxCount))
            saveHistory()
        }
    }
}
