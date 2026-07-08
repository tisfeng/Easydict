//
//  AnkiConnectClient.swift
//  Easydict
//
//  Created by leexiaobu on 2026/6/29.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import Foundation

// MARK: - AnkiEasydictField

/// Describes a piece of Easydict result data that can be mapped to an Anki
/// note field. Keeping these options explicit lets the settings UI expose
/// focused choices without tying Anki cards to one fixed Front/Back layout.
enum AnkiEasydictField: String, CaseIterable, Codable, Defaults.Serializable, Identifiable {
    case word
    case fullResult = "full_result"
    case phonetic
    case definition
    case translation
    case dictionaryText = "dictionary_text"
    case dictionaryHTML = "dictionary_html"
    case exchange
    case related
    case etymology

    // MARK: Internal

    var id: String { rawValue }

    var titleKey: String {
        "anki.easydict_field.\(rawValue)"
    }
}

// MARK: - AnkiFieldMapping

/// Stores one mapping from an Anki note field to one Easydict result field.
/// The stable id keeps SwiftUI rows editable while the raw value keeps the
/// persisted Defaults payload resilient to future field additions.
struct AnkiFieldMapping: Codable, Defaults.Serializable, Equatable, Identifiable {
    // MARK: Lifecycle

    init(id: UUID = UUID(), ankiField: String, easydictField: AnkiEasydictField) {
        self.id = id
        self.ankiField = ankiField
        self.fieldRawValue = easydictField.rawValue
    }

    // MARK: Internal

    let id: UUID
    var ankiField: String
    var fieldRawValue: String

    var easydictField: AnkiEasydictField {
        get { AnkiEasydictField(rawValue: fieldRawValue) ?? .fullResult }
        set { fieldRawValue = newValue.rawValue }
    }

    static func defaultMappings(
        ankiFields: [String] = [],
        frontFallback: String = "Front",
        backFallback: String = "Back"
    )
        -> [AnkiFieldMapping] {
        let fields = ankiFields
            .map(\.trimmed)
            .filter { !$0.isEmpty }

        if let front = fields.first {
            var mappings = [
                AnkiFieldMapping(ankiField: front, easydictField: .word),
            ]
            if let back = fields.dropFirst().first {
                mappings.append(AnkiFieldMapping(ankiField: back, easydictField: .fullResult))
            }
            return mappings
        }

        let front = frontFallback.trimmed.nonEmpty ?? "Front"
        let back = backFallback.trimmed.nonEmpty ?? "Back"

        return [
            AnkiFieldMapping(ankiField: front, easydictField: .word),
            AnkiFieldMapping(ankiField: back, easydictField: .fullResult),
        ]
    }
}

// MARK: - AnkiConnectClient

/// Sends dictionary lookup results to a local Anki Connect server.
/// The client supports one note action with configurable endpoint, deck, model,
/// and field mappings so users can choose which Easydict data lands in each
/// Anki note field.
@objcMembers
final class AnkiConnectClient: NSObject {
    // MARK: Lifecycle

    private override init() {}

    // MARK: Internal

    static let shared = AnkiConnectClient()

    func addNote(with result: QueryResult, completion: @escaping (Bool, String) -> ()) {
        guard Defaults[.enableAnkiConnect] else {
            completion(false, NSLocalizedString("anki.connect.disabled", comment: ""))
            return
        }

        guard let endpoint = configuredEndpoint(completion: completion) else {
            return
        }

        let mappings = configuredMappings()
        let fields = mappings.map { $0.ankiField.trimmed }
        guard !Defaults[.ankiConnectDeck].trimmed.isEmpty,
              !Defaults[.ankiConnectModel].trimmed.isEmpty,
              !mappings.isEmpty,
              fields.allSatisfy({ !$0.isEmpty })
        else {
            completion(false, NSLocalizedString("anki.connect.incomplete_configuration", comment: ""))
            return
        }

        guard Set(fields).count == fields.count else {
            completion(false, NSLocalizedString("anki.connect.duplicate_fields", comment: ""))
            return
        }

        let note = notePayload(from: result, mappings: mappings)
        let requestBody: [String: Any] = [
            "action": "addNote",
            "version": 6,
            "params": [
                "note": note,
            ],
        ]

        logInfo(
            "AnkiConnect addNote request deck=\(Defaults[.ankiConnectDeck].trimmed), "
                + "model=\(Defaults[.ankiConnectModel].trimmed), "
                + "fields=\(fields)"
        )

        performRequest(endpoint: endpoint, body: requestBody) { success, object, message in
            if success {
                logInfo("AnkiConnect addNote success result=\(String(describing: object?["result"]))")
            } else {
                logError("AnkiConnect addNote failed: \(message)")
            }
            completion(success, message)
        }
    }

    func fetchModelFieldNames(completion: @escaping (Bool, [String], String) -> ()) {
        guard let endpoint = configuredEndpoint(completion: { success, message in
            completion(success, [], message)
        }) else {
            return
        }

        let modelName = Defaults[.ankiConnectModel].trimmed
        guard !modelName.isEmpty else {
            completion(false, [], NSLocalizedString("anki.connect.incomplete_configuration", comment: ""))
            return
        }

        let requestBody: [String: Any] = [
            "action": "modelFieldNames",
            "version": 6,
            "params": [
                "modelName": modelName,
            ],
        ]

        logInfo("AnkiConnect modelFieldNames request model=\(modelName)")

        performRequest(endpoint: endpoint, body: requestBody) { success, object, message in
            guard success else {
                logError("AnkiConnect modelFieldNames failed: \(message)")
                completion(false, [], message)
                return
            }

            guard let fields = object?["result"] as? [String] else {
                let message = NSLocalizedString("anki.connect.invalid_response", comment: "")
                logError("AnkiConnect modelFieldNames invalid response")
                completion(false, [], message)
                return
            }

            logInfo("AnkiConnect modelFieldNames success fields=\(fields)")
            completion(true, fields, NSLocalizedString("anki.connect.fields_loaded", comment: ""))
        }
    }

    // MARK: Private

    private static func parseResponse(_ data: Data) -> (Bool, [String: Any]?, String) {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return (false, nil, NSLocalizedString("anki.connect.invalid_response", comment: ""))
        }

        if let error = object["error"], !(error is NSNull) {
            return (false, object, "\(error)")
        }

        return (true, object, NSLocalizedString("anki.connect.added", comment: ""))
    }

    private func configuredEndpoint(completion: (Bool, String) -> ()) -> URL? {
        guard let endpoint = URL(string: Defaults[.ankiConnectEndpoint]) else {
            completion(false, NSLocalizedString("anki.connect.invalid_endpoint", comment: ""))
            return nil
        }

        return endpoint
    }

    private func performRequest(
        endpoint: URL,
        body: [String: Any],
        completion: @escaping (Bool, [String: Any]?, String) -> ()
    ) {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(false, nil, error.localizedDescription)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error {
                    completion(false, nil, error.localizedDescription)
                    return
                }

                guard let data else {
                    completion(false, nil, NSLocalizedString("anki.connect.empty_response", comment: ""))
                    return
                }

                let response = Self.parseResponse(data)
                completion(response.0, response.1, response.2)
            }
        }.resume()
    }

    private func configuredMappings() -> [AnkiFieldMapping] {
        let mappings = Defaults[.ankiConnectFieldMappings]
        if !mappings.isEmpty {
            return mappings
        }

        return AnkiFieldMapping.defaultMappings(
            frontFallback: Defaults[.ankiConnectFrontField],
            backFallback: Defaults[.ankiConnectBackField]
        )
    }

    private func notePayload(from result: QueryResult, mappings: [AnkiFieldMapping]) -> [String: Any] {
        var fields: [String: String] = [:]
        for mapping in mappings {
            fields[mapping.ankiField.trimmed] = fieldText(mapping.easydictField, from: result)
        }

        return [
            "deckName": Defaults[.ankiConnectDeck].trimmed,
            "modelName": Defaults[.ankiConnectModel].trimmed,
            "fields": fields,
            "options": [
                "allowDuplicate": false,
            ],
            "tags": ["easydict"],
        ]
    }

    private func frontText(from result: QueryResult) -> String {
        result.queryText.trimmed.isEmpty ? result.queryModel.queryText : result.queryText.trimmed
    }

    private func backText(from result: QueryResult) -> String {
        let candidates = [
            wordResultText(from: result.wordResult),
            result.translatedText,
            result.copiedText,
            dictionaryText(from: result),
        ]

        return uniqueText(candidates).joined(separator: "\n\n")
    }

    private func fieldText(_ field: AnkiEasydictField, from result: QueryResult) -> String {
        switch field {
        case .word:
            return frontText(from: result)
        case .fullResult:
            return backText(from: result)
        case .phonetic:
            return phoneticText(from: result.wordResult) ?? ""
        case .definition:
            return definitionText(from: result.wordResult) ?? ""
        case .translation:
            return result.translatedText?.trimmed ?? ""
        case .dictionaryText:
            return dictionaryText(from: result) ?? ""
        case .dictionaryHTML:
            return dictionaryHTML(from: result) ?? ""
        case .exchange:
            return exchangeText(from: result.wordResult) ?? ""
        case .related:
            return relatedText(from: result.wordResult) ?? ""
        case .etymology:
            return result.wordResult?.etymology?.trimmed ?? ""
        }
    }

    private func dictionaryText(from result: QueryResult) -> String? {
        let candidates = [
            result.innerTexts?.joined(separator: "\n\n"),
            result.htmlStrings?.joined(separator: "\n\n"),
            result.htmlString,
        ]

        return candidates
            .compactMap { $0?.trimmed }
            .first { !$0.isEmpty }
    }

    private func dictionaryHTML(from result: QueryResult) -> String? {
        let candidates = [
            result.htmlStrings?.joined(separator: "\n\n"),
            result.htmlString,
        ]

        return candidates
            .compactMap { $0?.trimmed }
            .first { !$0.isEmpty }
    }

    private func wordResultText(from wordResult: EZTranslateWordResult?) -> String? {
        guard let wordResult else { return nil }

        let candidates = [
            phoneticText(from: wordResult),
            definitionText(from: wordResult),
            exchangeText(from: wordResult),
            wordResult.etymology?.trimmed,
            relatedText(from: wordResult),
        ]

        return joinedText(candidates)
    }

    private func phoneticText(from wordResult: EZTranslateWordResult?) -> String? {
        guard let phonetics = wordResult?.phonetics else { return nil }

        let values = phonetics.compactMap { phonetic -> String? in
            guard let value = phonetic.value?.trimmed, !value.isEmpty else { return nil }
            let name = phonetic.name?.trimmed ?? ""
            return name.isEmpty ? "/\(value)/" : "\(name) /\(value)/"
        }

        return joinedText(values)
    }

    private func definitionText(from wordResult: EZTranslateWordResult?) -> String? {
        guard let wordResult else { return nil }

        var lines = partLines(from: wordResult.parts)
        if let simpleWords = wordResult.simpleWords {
            lines.append(contentsOf: simpleWords.compactMap { simpleWord in
                let word = simpleWord.word.trimmed
                let means = simpleWord.meansText.trimmed
                guard !word.isEmpty || !means.isEmpty else { return nil }

                let part = simpleWord.part?.trimmed ?? ""
                let prefix = [word, part].filter { !$0.isEmpty }.joined(separator: " ")
                return prefix.isEmpty ? means : "\(prefix): \(means)"
            })
        }

        return joinedText(lines)
    }

    private func exchangeText(from wordResult: EZTranslateWordResult?) -> String? {
        guard let exchanges = wordResult?.exchanges else { return nil }

        let lines = exchanges.compactMap { exchange -> String? in
            let words = exchange.words
                .map(\.trimmed)
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            guard !words.isEmpty else { return nil }

            let name = exchange.name.trimmed
            return name.isEmpty ? words : "\(name): \(words)"
        }

        return joinedText(lines)
    }

    private func relatedText(from wordResult: EZTranslateWordResult?) -> String? {
        guard let wordResult else { return nil }

        let lines = partLines(from: wordResult.synonyms, title: "Synonyms")
            + partLines(from: wordResult.antonyms, title: "Antonyms")
            + partLines(from: wordResult.collocation, title: "Collocation")
        return joinedText(lines)
    }

    private func partLines(from parts: [EZTranslatePart]?, title: String? = nil) -> [String] {
        guard let parts else { return [] }

        var lines = parts.flatMap { part in
            part.means.compactMap { mean -> String? in
                let value = mean.trimmed
                guard !value.isEmpty else { return nil }

                let label = part.part?.trimmed ?? ""
                return label.isEmpty ? value : "\(label) \(value)"
            }
        }

        if !lines.isEmpty, let title {
            lines.insert(title, at: 0)
        }

        return lines
    }

    private func joinedText(_ candidates: [String?]) -> String? {
        let text = candidates
            .compactMap { $0?.trimmed }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return text.isEmpty ? nil : text
    }

    private func uniqueText(_ candidates: [String?]) -> [String] {
        var seen = Set<String>()
        var values: [String] = []

        for candidate in candidates {
            guard let value = candidate?.trimmed, !value.isEmpty else { continue }
            let normalized = value.replacingOccurrences(of: "\r\n", with: "\n")
            guard seen.insert(normalized).inserted else { continue }
            values.append(value)
        }

        return values
    }
}

// MARK: - String

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    fileprivate var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
