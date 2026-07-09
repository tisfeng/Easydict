//
//  AdvancedTabAnkiSection.swift
//  Easydict
//
//  Created by leexiaobu on 2026/7/9.
//  Copyright © 2026 izual. All rights reserved.
//

import Defaults
import SFSafeSymbols
import SwiftUI

// MARK: - AdvancedTabAnkiSection

/// Presents the Anki Connect controls used by Advanced settings.
/// The view owns field loading, template mapping, and preview state so the
/// main advanced tab stays focused on shared settings.
struct AdvancedTabAnkiSection: View {
    // MARK: Internal

    var body: some View {
        Section {
            Toggle(isOn: $enableAnkiConnect) {
                AdvancedTabItemView(
                    color: ankiIconColor,
                    icon: .externaldriveConnectedToLineBelow,
                    labelText: "setting.advance.enable_anki_connect"
                )
            }

            endpointRow
            deckRow
            modelRow
            mappingRow
            previewRow
        } header: {
            Text("setting.advance.header.anki_connect")
        }
        .onAppear {
            ensureAnkiMappings()
        }
    }

    // MARK: Private

    @State private var isFetchingFields = false
    @State private var isLoadingPreview = false
    @State private var previewTextInput = ""
    @State private var previewServiceID = ServiceType.youdao.rawValue
    @State private var previewError: String?
    @State private var previewValues: [AnkiFieldPreviewValue] = []
    @State private var previewFields: [AnkiRenderedFieldPreview] = []

    @Default(.enableAnkiConnect) private var enableAnkiConnect
    @Default(.ankiConnectEndpoint) private var ankiConnectEndpoint
    @Default(.ankiConnectDeck) private var ankiConnectDeck
    @Default(.ankiConnectModel) private var ankiConnectModel
    @Default(.ankiConnectFrontField) private var ankiConnectFrontField
    @Default(.ankiConnectBackField) private var ankiConnectBackField
    @Default(.ankiConnectModelFields) private var ankiConnectModelFields
    @Default(.ankiConnectFieldMappings) private var ankiConnectFieldMappings
}

extension AdvancedTabAnkiSection {
    private var ankiIconColor: Color {
        enableAnkiConnect ? .green : .red
    }

    private var previewServiceTypes: [ServiceType] {
        if Defaults[.mdictDictionaries].contains(where: \.enabled) {
            return [.youdao, .appleDictionary, .mDict, .google]
        }

        return [.youdao, .appleDictionary, .google]
    }

    private var endpointRow: some View {
        LabeledContent {
            TextField(text: $ankiConnectEndpoint, prompt: Text(verbatim: "http://127.0.0.1:8765")) {
                EmptyView()
            }
            .frame(width: 260)
            .fixedSize(horizontal: true, vertical: false)
        } label: {
            AdvancedTabItemView(
                color: ankiIconColor,
                icon: .network,
                labelText: "setting.advance.anki_endpoint",
                subtitleText: "setting.advance.anki_endpoint_desc"
            )
        }
    }

    private var deckRow: some View {
        LabeledContent {
            TextField(text: $ankiConnectDeck, prompt: Text(verbatim: "Default")) {
                EmptyView()
            }
            .frame(width: 180)
            .fixedSize(horizontal: true, vertical: false)
        } label: {
            AdvancedTabItemView(
                color: ankiIconColor,
                icon: .book,
                labelText: "setting.advance.anki_deck"
            )
        }
    }

    private var modelRow: some View {
        LabeledContent {
            TextField(text: $ankiConnectModel, prompt: Text(verbatim: "Basic")) {
                EmptyView()
            }
            .frame(width: 180)
            .fixedSize(horizontal: true, vertical: false)
        } label: {
            AdvancedTabItemView(
                color: ankiIconColor,
                icon: .ellipsisBubbleFill,
                labelText: "setting.advance.anki_model"
            )
        }
    }

    private var mappingRow: some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 8) {
                ForEach($ankiConnectFieldMappings) { mapping in
                    mappingControl(mapping)
                }

                HStack(spacing: 8) {
                    Button {
                        addAnkiMapping()
                    } label: {
                        Label("setting.advance.anki_add_mapping", systemSymbol: .plus)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        fetchAnkiFields()
                    } label: {
                        if isFetchingFields {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemSymbol: .arrowClockwise)
                        }
                    }
                    .disabled(isFetchingFields)
                    .help(Text("setting.advance.anki_fetch_fields"))
                }
            }
        } label: {
            AdvancedTabItemView(
                color: ankiIconColor,
                icon: .textformat,
                labelText: "setting.advance.anki_field_mapping",
                subtitleText: "setting.advance.anki_field_mapping_desc"
            )
        }
    }

    private var previewRow: some View {
        LabeledContent {
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Picker(selection: $previewServiceID) {
                        ForEach(previewServiceTypes, id: \.rawValue) { serviceType in
                            Text(verbatim: previewServiceName(serviceType))
                                .tag(serviceType.rawValue)
                        }
                    } label: {
                        EmptyView()
                    }
                    .labelsHidden()
                    .frame(width: 140)

                    TextField(
                        text: $previewTextInput,
                        prompt: Text("setting.advance.anki_preview_word_prompt")
                    ) {
                        EmptyView()
                    }
                    .frame(width: 180)

                    Button {
                        Task {
                            await loadAnkiPreview()
                        }
                    } label: {
                        if isLoadingPreview {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Label("setting.advance.anki_preview_query", systemSymbol: .magnifyingglass)
                        }
                    }
                    .disabled(isLoadingPreview)
                }

                if let previewError {
                    Text(verbatim: previewError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(width: 430, alignment: .leading)
                }

                previewContent
            }
        } label: {
            AdvancedTabItemView(
                color: ankiIconColor,
                icon: .magnifyingglass,
                labelText: "setting.advance.anki_preview",
                subtitleText: "setting.advance.anki_preview_desc"
            )
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        if !previewValues.isEmpty || !previewFields.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                if !previewValues.isEmpty {
                    previewVariablesSection
                }

                if !previewFields.isEmpty {
                    Divider()
                    previewRenderedFieldsSection
                }
            }
            .frame(width: 430, alignment: .leading)
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }

    private var previewVariablesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("setting.advance.anki_preview_variables")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(previewValues) { value in
                previewVariableRow(value)
            }
        }
    }

    private var previewRenderedFieldsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("setting.advance.anki_preview_rendered_fields")
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(previewFields) { field in
                previewRenderedFieldRow(field)
            }
        }
    }

    private func mappingControl(_ mapping: Binding<AnkiFieldMapping>) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Picker(selection: mapping.ankiField) {
                ForEach(ankiFieldOptions(current: mapping.wrappedValue.ankiField), id: \.self) { field in
                    Text(verbatim: field)
                        .tag(field)
                }
            } label: {
                EmptyView()
            }
            .labelsHidden()
            .frame(width: 140)

            Image(systemSymbol: .arrowRight)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            TextEditorWithPlaceholder(
                text: mapping.template,
                placeholder: "setting.advance.anki_template_placeholder",
                font: .body,
                lineSpacing: 3
            )
            .frame(width: 260)
            .frame(minHeight: 48, maxHeight: 88)
            .padding(.horizontal, 3)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )

            Menu {
                ForEach(AnkiEasydictField.allCases) { field in
                    Button {
                        insertAnkiToken(field, mappingID: mapping.wrappedValue.id)
                    } label: {
                        HStack {
                            Text(verbatim: field.templateToken)
                            Text(LocalizedStringKey(field.titleKey))
                        }
                    }
                }
            } label: {
                Image(systemSymbol: .plus)
            }
            .buttonStyle(.borderless)
            .help(Text("setting.advance.anki_insert_variable"))
            .padding(.top, 6)

            Button {
                removeAnkiMapping(id: mapping.wrappedValue.id)
            } label: {
                Image(systemSymbol: .minusCircle)
            }
            .buttonStyle(.borderless)
            .disabled(ankiConnectFieldMappings.count <= 1)
            .help(Text("setting.advance.anki_remove_mapping"))
            .padding(.top, 6)
        }
    }

    private func previewVariableRow(_ value: AnkiFieldPreviewValue) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: value.field.templateToken)
                    .font(.caption)
                Text(LocalizedStringKey(value.field.titleKey))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 106, alignment: .leading)

            Text(verbatim: displayPreviewText(value.value))
                .font(.caption)
                .lineLimit(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func previewRenderedFieldRow(_ field: AnkiRenderedFieldPreview) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: field.ankiField)
                    .font(.caption)
                Text(verbatim: field.template)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 106, alignment: .leading)

            Text(verbatim: displayPreviewText(field.value))
                .font(.caption)
                .lineLimit(4)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fetchAnkiFields() {
        isFetchingFields = true
        AnkiConnectClient.shared.fetchModelFieldNames { success, fields, message in
            isFetchingFields = false

            guard success else {
                EZToast.showText(message)
                return
            }

            guard !fields.isEmpty else {
                EZToast.showText(NSLocalizedString("anki.connect.insufficient_fields", comment: ""))
                return
            }

            ankiConnectModelFields = fields
            if ankiConnectFieldMappings.isEmpty {
                ankiConnectFieldMappings = AnkiFieldMapping.defaultMappings(
                    ankiFields: fields,
                    frontFallback: ankiConnectFrontField,
                    backFallback: ankiConnectBackField
                )
            }
            EZToast.showText(message)
        }
    }

    private func ensureAnkiMappings() {
        guard ankiConnectFieldMappings.isEmpty else { return }

        ankiConnectFieldMappings = AnkiFieldMapping.defaultMappings(
            ankiFields: ankiConnectModelFields,
            frontFallback: ankiConnectFrontField,
            backFallback: ankiConnectBackField
        )
    }

    private func addAnkiMapping() {
        ensureAnkiMappings()
        ankiConnectFieldMappings.append(
            AnkiFieldMapping(
                ankiField: nextAnkiField(),
                easydictField: nextEasydictField()
            )
        )
    }

    private func removeAnkiMapping(id: UUID) {
        guard ankiConnectFieldMappings.count > 1 else { return }
        ankiConnectFieldMappings.removeAll { $0.id == id }
    }

    private func insertAnkiToken(_ field: AnkiEasydictField, mappingID: UUID) {
        guard let index = ankiConnectFieldMappings.firstIndex(where: { $0.id == mappingID }) else { return }

        let token = field.templateToken
        let template = ankiConnectFieldMappings[index].template
        if template.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ankiConnectFieldMappings[index].template = token
        } else if template.hasSuffix("\n") || template.hasSuffix(" ") {
            ankiConnectFieldMappings[index].template += token
        } else {
            ankiConnectFieldMappings[index].template += "\n\(token)"
        }
    }

    private func ankiFieldOptions(current: String) -> [String] {
        let baseFields = ankiConnectModelFields.isEmpty
            ? [ankiConnectFrontField, ankiConnectBackField]
            : ankiConnectModelFields
        return uniqueFields(baseFields + [current])
    }

    private func nextAnkiField() -> String {
        let usedFields = Set(ankiConnectFieldMappings.map { cleanField($0.ankiField) })
        return ankiFieldOptions(current: "")
            .first { !usedFields.contains(cleanField($0)) } ?? ""
    }

    private func nextEasydictField() -> AnkiEasydictField {
        let usedFields = Set(ankiConnectFieldMappings.map(\.fieldRawValue))
        let candidates: [AnkiEasydictField] = [
            .phonetic,
            .definition,
            .translation,
            .dictionaryText,
            .exchange,
            .related,
            .etymology,
            .dictionaryHTML,
            .fullResult,
        ]
        return candidates.first { !usedFields.contains($0.rawValue) } ?? .fullResult
    }

    private func uniqueFields(_ fields: [String]) -> [String] {
        var seen = Set<String>()
        return fields.compactMap { field in
            let value = cleanField(field)
            guard !value.isEmpty, seen.insert(value).inserted else { return nil }
            return value
        }
    }

    private func effectiveAnkiMappings() -> [AnkiFieldMapping] {
        if !ankiConnectFieldMappings.isEmpty {
            return ankiConnectFieldMappings
        }

        return AnkiFieldMapping.defaultMappings(
            ankiFields: ankiConnectModelFields,
            frontFallback: ankiConnectFrontField,
            backFallback: ankiConnectBackField
        )
    }

    private func loadAnkiPreview() async {
        let text = cleanField(previewTextInput)
        guard !text.isEmpty else {
            previewError = NSLocalizedString("anki.connect.preview_empty_word", comment: "")
            previewValues = []
            previewFields = []
            return
        }

        isLoadingPreview = true
        previewError = nil

        do {
            let serviceID = normalizedPreviewServiceID()
            previewServiceID = serviceID
            let result = try await queryAnkiPreview(text: text, serviceID: serviceID)
            previewValues = AnkiTemplateRenderer.previewValues(from: result)
            previewFields = AnkiTemplateRenderer.renderedPreviewFields(
                from: result,
                mappings: effectiveAnkiMappings()
            )
        } catch {
            previewError = error.localizedDescription
            previewValues = []
            previewFields = []
        }

        isLoadingPreview = false
    }

    private func queryAnkiPreview(text: String, serviceID: String) async throws -> QueryResult {
        guard let service = QueryServiceFactory.shared.service(withTypeId: serviceID) else {
            let message = String(localized: "anki.connect.preview_unsupported_service")
            throw QueryError(type: .unsupportedServiceType, message: message)
        }

        let model = QueryModel()
        model.inputText = text
        let detectedModel = try await DetectManager(model: model).detectText(text)
        do {
            return try await service.startQuery(detectedModel)
        } catch let error as QueryError where error.type == .noResult {
            return emptyPreviewResult(text: text, model: detectedModel, serviceID: serviceID)
        }
    }

    private func emptyPreviewResult(text: String, model: QueryModel, serviceID: String) -> QueryResult {
        let result = QueryResult()
        result.queryModel = model
        result.queryText = model.queryText.isEmpty ? text : model.queryText
        result.serviceTypeWithUniqueIdentifier = serviceID
        result.from = model.queryFromLanguage
        result.to = model.queryTargetLanguage
        return result
    }

    private func normalizedPreviewServiceID() -> String {
        let serviceIDs = previewServiceTypes.map(\.rawValue)
        if serviceIDs.contains(previewServiceID) {
            return previewServiceID
        }

        return serviceIDs.first ?? ServiceType.youdao.rawValue
    }

    private func previewServiceName(_ serviceType: ServiceType) -> String {
        QueryServiceFactory.shared.service(withTypeId: serviceType.rawValue)?.name() ?? serviceType.rawValue
    }

    private func displayPreviewText(_ text: String) -> String {
        let value = cleanField(text)
        return value.isEmpty ? String(localized: "setting.advance.anki_preview_empty") : value
    }

    private func cleanField(_ field: String) -> String {
        field.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
