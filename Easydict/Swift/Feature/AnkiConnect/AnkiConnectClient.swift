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

    var tokenName: String {
        switch self {
        case .word:
            return "Word"
        case .fullResult:
            return "FullResult"
        case .phonetic:
            return "Phonetic"
        case .definition:
            return "Definition"
        case .translation:
            return "Translation"
        case .dictionaryText:
            return "DictionaryText"
        case .dictionaryHTML:
            return "DictionaryHTML"
        case .exchange:
            return "Exchange"
        case .related:
            return "Related"
        case .etymology:
            return "Etymology"
        }
    }

    var templateToken: String {
        "{\(tokenName)}"
    }
}

// MARK: - AnkiFieldMapping

/// Stores one mapping from an Anki note field to an Easydict template.
/// The stable id keeps SwiftUI rows editable while the raw value preserves
/// compatibility with older single-field mapping settings.
struct AnkiFieldMapping: Codable, Defaults.Serializable, Equatable, Identifiable {
    // MARK: Lifecycle

    init(id: UUID = UUID(), ankiField: String, easydictField: AnkiEasydictField) {
        self.id = id
        self.ankiField = ankiField
        self.fieldRawValue = easydictField.rawValue
        self.template = easydictField.templateToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.ankiField = try container.decodeIfPresent(String.self, forKey: .ankiField) ?? ""
        self.fieldRawValue = try container
            .decodeIfPresent(String.self, forKey: .fieldRawValue) ?? AnkiEasydictField.fullResult.rawValue

        if let savedTemplate = try container.decodeIfPresent(String.self, forKey: .template) {
            self.template = savedTemplate
        } else {
            let field = AnkiEasydictField(rawValue: fieldRawValue) ?? .fullResult
            self.template = field.templateToken
        }
    }

    // MARK: Internal

    let id: UUID
    var ankiField: String
    var fieldRawValue: String
    var template: String

    var easydictField: AnkiEasydictField {
        get { AnkiEasydictField(rawValue: fieldRawValue) ?? .fullResult }
        set {
            fieldRawValue = newValue.rawValue
            template = newValue.templateToken
        }
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

    // MARK: Private

    /// Persists the current template while still decoding earlier mappings
    /// that only stored a single Easydict field value.
    private enum CodingKeys: String, CodingKey {
        case id
        case ankiField
        case fieldRawValue
        case template
    }
}

// MARK: - AnkiFieldPreviewValue

/// Represents one available Easydict variable and the value extracted from a
/// query result. Settings uses this for previewing what each template token
/// expands to before a note is sent to Anki.
struct AnkiFieldPreviewValue: Identifiable {
    let field: AnkiEasydictField
    let value: String

    var id: String { field.rawValue }
}

// MARK: - AnkiRenderedFieldPreview

/// Represents the rendered output for one Anki field mapping. It mirrors the
/// payload sent to Anki Connect so the settings preview can show the final
/// field values without creating a card.
struct AnkiRenderedFieldPreview: Identifiable {
    let id: UUID
    let ankiField: String
    let template: String
    let value: String
}

// MARK: - AnkiTemplateRenderer

/// Extracts Easydict result values and renders Anki field templates.
/// Both card submission and settings preview use this type so users see the
/// same text that will be written to Anki.
enum AnkiTemplateRenderer {
    // MARK: Internal

    static func fieldValues(from result: QueryResult) -> [AnkiEasydictField: String] {
        [
            .word: frontText(from: result),
            .fullResult: backText(from: result),
            .phonetic: phoneticText(from: result.wordResult) ?? "",
            .definition: definitionText(from: result.wordResult) ?? "",
            .translation: result.translatedText?.trimmed ?? "",
            .dictionaryText: dictionaryText(from: result) ?? "",
            .dictionaryHTML: dictionaryHTML(from: result) ?? "",
            .exchange: exchangeText(from: result.wordResult) ?? "",
            .related: relatedText(from: result.wordResult) ?? "",
            .etymology: result.wordResult?.etymology?.trimmed ?? "",
        ]
    }

    static func previewValues(from result: QueryResult) -> [AnkiFieldPreviewValue] {
        let values = fieldValues(from: result)
        return AnkiEasydictField.allCases.map { field in
            AnkiFieldPreviewValue(field: field, value: values[field] ?? "")
        }
    }

    static func renderedFields(
        from result: QueryResult,
        mappings: [AnkiFieldMapping]
    )
        -> [String: String] {
        let values = fieldValues(from: result)
        var fields: [String: String] = [:]

        for mapping in mappings {
            fields[mapping.ankiField.trimmed] = render(mapping.template, values: values)
        }

        return fields
    }

    static func renderedPreviewFields(
        from result: QueryResult,
        mappings: [AnkiFieldMapping]
    )
        -> [AnkiRenderedFieldPreview] {
        let values = fieldValues(from: result)
        return mappings.map { mapping in
            AnkiRenderedFieldPreview(
                id: mapping.id,
                ankiField: mapping.ankiField.trimmed,
                template: mapping.template,
                value: render(mapping.template, values: values)
            )
        }
    }

    static func render(
        _ template: String,
        values: [AnkiEasydictField: String]
    )
        -> String {
        var rendered = template
        for field in AnkiEasydictField.allCases {
            let value = values[field] ?? ""
            rendered = rendered.replacingOccurrences(
                of: field.templateToken,
                with: value,
                options: [.caseInsensitive]
            )
        }
        return rendered.trimmed
    }

    // MARK: Private

    private static func frontText(from result: QueryResult) -> String {
        result.queryText.trimmed.isEmpty ? result.queryModel.queryText : result.queryText.trimmed
    }

    private static func backText(from result: QueryResult) -> String {
        let candidates = [
            wordResultText(from: result.wordResult),
            result.translatedText,
            result.copiedText,
            dictionaryContentForBack(from: result),
        ]

        return uniqueText(candidates).joined(separator: "\n\n")
    }

    private static func dictionaryText(from result: QueryResult) -> String? {
        let innerText = result.innerTexts?.joined(separator: "\n\n")
        let entryHTML = result.htmlStrings?.joined(separator: "\n\n")
        let renderedHTML = result.htmlString

        return firstNonEmpty([innerText, entryHTML, renderedHTML])
    }

    private static func dictionaryContentForBack(from result: QueryResult) -> String? {
        if prefersRenderedDictionaryHTML(result) {
            return dictionaryHTML(from: result)
        }

        return dictionaryText(from: result)
    }

    private static func dictionaryHTML(from result: QueryResult) -> String? {
        if prefersRenderedDictionaryHTML(result) {
            return firstNonEmpty([
                result.htmlString,
                result.htmlStrings?.joined(separator: "\n\n"),
            ])
        }

        return firstNonEmpty([
            result.htmlStrings?.joined(separator: "\n\n"),
            result.htmlString,
        ])
    }

    private static func prefersRenderedDictionaryHTML(_ result: QueryResult) -> Bool {
        result.serviceTypeWithUniqueIdentifier == ServiceType.appleDictionary.rawValue ||
            result.serviceTypeWithUniqueIdentifier == ServiceType.mDict.rawValue
    }

    private static func wordResultText(from wordResult: EZTranslateWordResult?) -> String? {
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

    private static func phoneticText(from wordResult: EZTranslateWordResult?) -> String? {
        guard let phonetics = wordResult?.phonetics else { return nil }

        let values = phonetics.compactMap { phonetic -> String? in
            guard let value = phonetic.value?.trimmed, !value.isEmpty else { return nil }
            let name = phonetic.name?.trimmed ?? ""
            return name.isEmpty ? "/\(value)/" : "\(name) /\(value)/"
        }

        return joinedText(values)
    }

    private static func definitionText(from wordResult: EZTranslateWordResult?) -> String? {
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

    private static func exchangeText(from wordResult: EZTranslateWordResult?) -> String? {
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

    private static func relatedText(from wordResult: EZTranslateWordResult?) -> String? {
        guard let wordResult else { return nil }

        let lines = partLines(from: wordResult.synonyms, title: "Synonyms")
            + partLines(from: wordResult.antonyms, title: "Antonyms")
            + partLines(from: wordResult.collocation, title: "Collocation")
        return joinedText(lines)
    }

    private static func partLines(from parts: [EZTranslatePart]?, title: String? = nil) -> [String] {
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

    private static func joinedText(_ candidates: [String?]) -> String? {
        let text = candidates
            .compactMap { $0?.trimmed }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return text.isEmpty ? nil : text
    }

    private static func firstNonEmpty(_ candidates: [String?]) -> String? {
        candidates
            .compactMap { $0?.trimmed }
            .first { !$0.isEmpty }
    }

    private static func uniqueText(_ candidates: [String?]) -> [String] {
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
        let templates = mappings.map { $0.template.trimmed }
        guard !Defaults[.ankiConnectDeck].trimmed.isEmpty,
              !Defaults[.ankiConnectModel].trimmed.isEmpty,
              !mappings.isEmpty,
              fields.allSatisfy({ !$0.isEmpty }),
              templates.allSatisfy({ !$0.isEmpty })
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
        let fields = AnkiTemplateRenderer.renderedFields(from: result, mappings: mappings)

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
