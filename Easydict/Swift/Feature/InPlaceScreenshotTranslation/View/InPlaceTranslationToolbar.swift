//
//  InPlaceTranslationToolbar.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import SwiftUI

// MARK: - InPlaceTranslationToolbar

/// Responsive bottom controls for live updates, languages, provider, display,
/// explicit clipboard writes, pinning, reselection, and closure.
struct InPlaceTranslationToolbar: View {
    // MARK: Internal

    @ObservedObject var viewModel: InPlaceTranslationViewModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            expandedToolbar
            compactToolbar
            narrowToolbar
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.bar)
    }

    // MARK: Private

    private var statusColor: Color {
        switch viewModel.processingState {
        case .ready:
            .green
        case .partialFailure, .recoverableError:
            .orange
        default:
            .accentColor
        }
    }

    private var pinKey: LocalizedStringKey {
        viewModel.configuration.isPinned
            ? "in_place_screenshot_translation.toolbar.unpin"
            : "in_place_screenshot_translation.toolbar.pin"
    }

    private var selectedServiceName: String {
        viewModel.serviceOptions.first {
            $0.identifier == viewModel.configuration.serviceIdentifier
        }?.displayName ?? String(
            localized: "in_place_screenshot_translation.status.service_unavailable"
        )
    }

    private var narrowDisplayModeKey: LocalizedStringKey {
        viewModel.configuration.renderMode == .translated
            ? "in_place_screenshot_translation.display.translated"
            : "in_place_screenshot_translation.display.original"
    }

    private var expandedToolbar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                liveToggle
                statusView
                permissionRecoveryButton
                Spacer(minLength: 4)
                sourceMenu
                Button("in_place_screenshot_translation.toolbar.swap_languages") {
                    viewModel.swapLanguages()
                }
                .controlSize(.small)
                targetMenu
                displayPicker
                Button("in_place_screenshot_translation.toolbar.refresh") {
                    viewModel.refresh()
                }
                .controlSize(.small)
            }

            HStack(spacing: 8) {
                serviceMenu
                Spacer()
                Button("in_place_screenshot_translation.toolbar.copy") {
                    viewModel.copyTranslation()
                }
                Button(pinKey) {
                    viewModel.togglePinned()
                }
                Button("in_place_screenshot_translation.toolbar.reselect") {
                    viewModel.reselect()
                }
                Button("in_place_screenshot_translation.toolbar.close") {
                    viewModel.close()
                }
            }
            .controlSize(.small)
        }
    }

    private var compactToolbar: some View {
        HStack(spacing: 7) {
            liveToggle.labelsHidden()
            statusView
            sourceMenu
            targetMenu
            displayPicker
                .frame(maxWidth: 145)
            Menu("in_place_screenshot_translation.toolbar.more") {
                overflowActions
            }
            .controlSize(.small)
        }
    }

    /// Keeps the primary live/language/display controls usable at the panel's
    /// 360-point minimum width while moving every secondary action to overflow.
    private var narrowToolbar: some View {
        HStack(spacing: 6) {
            liveToggle.labelsHidden()
            narrowSourceMenu
            Image(systemName: "arrow.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            narrowTargetMenu
            Button {
                viewModel.toggleRenderMode()
            } label: {
                Image(
                    systemName: viewModel.configuration.renderMode == .translated
                        ? "doc.text.fill"
                        : "photo"
                )
            }
            .help(Text(narrowDisplayModeKey))
            .accessibilityLabel(Text(narrowDisplayModeKey))
            Menu {
                overflowActions
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .help(Text("in_place_screenshot_translation.toolbar.more"))
            .accessibilityLabel(Text("in_place_screenshot_translation.toolbar.more"))
        }
        .controlSize(.small)
        .frame(maxWidth: .infinity)
    }

    private var liveToggle: some View {
        Toggle(
            "in_place_screenshot_translation.toolbar.live_updates",
            isOn: Binding(
                get: { viewModel.configuration.liveUpdatesEnabled },
                set: viewModel.setLiveUpdatesEnabled
            )
        )
        .toggleStyle(.switch)
        .controlSize(.small)
        .help(Text("in_place_screenshot_translation.privacy.notice"))
    }

    @ViewBuilder
    private var permissionRecoveryButton: some View {
        if viewModel.captureAvailability == .permissionDenied {
            Button("open_system_settings") {
                viewModel.openScreenRecordingSettings()
            }
            .controlSize(.small)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            statusText
        }
        .font(.caption)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.regularMaterial, in: Capsule())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusText: some View {
        if viewModel.lifecycle == .paused {
            Text("in_place_screenshot_translation.status.paused")
        } else {
            switch viewModel.captureAvailability {
            case .permissionDenied:
                Text("in_place_screenshot_translation.error.permission")
            case .displayDisconnected:
                Text("in_place_screenshot_translation.error.display_disconnected")
            default:
                processingStatusText
            }
        }
    }

    @ViewBuilder
    private var processingStatusText: some View {
        switch viewModel.processingState {
        case .idle:
            Text("in_place_screenshot_translation.status.preparing")
        case .debouncing:
            Text("in_place_screenshot_translation.status.recovering_capture")
        case .recognizing:
            Text("in_place_screenshot_translation.status.recognizing")
        case let .translating(_, completed, total):
            Text("in_place_screenshot_translation.status.translating")
            Text(verbatim: " \(completed)/\(total)")
        case .ready:
            Text("in_place_screenshot_translation.status.ready")
        case .partialFailure:
            Text("in_place_screenshot_translation.status.partial_failure")
        case .noText:
            Text("in_place_screenshot_translation.status.no_text")
        case let .recoverableError(_, category):
            errorText(category)
        }
    }

    private var sourceMenu: some View {
        Menu {
            ForEach(viewModel.sourceLanguages, id: \.rawValue) { language in
                Button {
                    viewModel.setSourceLanguage(language)
                } label: {
                    Text(verbatim: "\(language.flagEmoji) \(language.localizedName)")
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("in_place_screenshot_translation.toolbar.source_language")
                    .font(.caption2)
                Text(verbatim: viewModel.configuration.sourceLanguage.localizedName)
                    .lineLimit(1)
                if viewModel.configuration.sourceLanguage == .auto,
                   let detected = viewModel.snapshot?.detectedLanguage,
                   detected != .auto {
                    Text(verbatim: detected.localizedName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .controlSize(.small)
    }

    private var narrowSourceMenu: some View {
        Menu {
            ForEach(viewModel.sourceLanguages, id: \.rawValue) { language in
                Button {
                    viewModel.setSourceLanguage(language)
                } label: {
                    Text(verbatim: "\(language.flagEmoji) \(language.localizedName)")
                }
            }
        } label: {
            Text(verbatim: viewModel.configuration.sourceLanguage.flagEmoji)
                .frame(minWidth: 22)
        }
        .help(Text(verbatim: viewModel.configuration.sourceLanguage.localizedName))
        .accessibilityLabel(Text("in_place_screenshot_translation.toolbar.source_language"))
        .accessibilityValue(Text(verbatim: viewModel.configuration.sourceLanguage.localizedName))
    }

    private var targetMenu: some View {
        Menu {
            ForEach(viewModel.availableTargetLanguages, id: \.rawValue) { language in
                Button {
                    viewModel.setTargetLanguage(language)
                } label: {
                    Text(verbatim: "\(language.flagEmoji) \(language.localizedName)")
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("in_place_screenshot_translation.toolbar.target_language")
                    .font(.caption2)
                Text(verbatim: viewModel.configuration.targetLanguage.localizedName)
                    .lineLimit(1)
            }
        }
        .controlSize(.small)
    }

    private var narrowTargetMenu: some View {
        Menu {
            ForEach(viewModel.availableTargetLanguages, id: \.rawValue) { language in
                Button {
                    viewModel.setTargetLanguage(language)
                } label: {
                    Text(verbatim: "\(language.flagEmoji) \(language.localizedName)")
                }
            }
        } label: {
            Text(verbatim: viewModel.configuration.targetLanguage.flagEmoji)
                .frame(minWidth: 22)
        }
        .help(Text(verbatim: viewModel.configuration.targetLanguage.localizedName))
        .accessibilityLabel(Text("in_place_screenshot_translation.toolbar.target_language"))
        .accessibilityValue(Text(verbatim: viewModel.configuration.targetLanguage.localizedName))
    }

    @ViewBuilder
    private var overflowActions: some View {
        if viewModel.captureAvailability == .permissionDenied {
            Button("open_system_settings") {
                viewModel.openScreenRecordingSettings()
            }
            Divider()
        }
        Button("in_place_screenshot_translation.toolbar.swap_languages") {
            viewModel.swapLanguages()
        }
        Button("in_place_screenshot_translation.toolbar.refresh") {
            viewModel.refresh()
        }
        serviceMenu
        Divider()
        Button("in_place_screenshot_translation.toolbar.copy") {
            viewModel.copyTranslation()
        }
        Button(pinKey) {
            viewModel.togglePinned()
        }
        Button("in_place_screenshot_translation.toolbar.reselect") {
            viewModel.reselect()
        }
        Button("in_place_screenshot_translation.toolbar.close") {
            viewModel.close()
        }
    }

    private var serviceMenu: some View {
        Menu {
            ForEach(viewModel.serviceOptions) { option in
                Button {
                    viewModel.setServiceIdentifier(option.identifier)
                } label: {
                    Text(verbatim: option.displayName)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text("in_place_screenshot_translation.toolbar.service")
                    .font(.caption2)
                Text(verbatim: selectedServiceName)
                    .lineLimit(1)
            }
        }
        .disabled(viewModel.serviceOptions.isEmpty)
    }

    private var displayPicker: some View {
        Picker(
            "in_place_screenshot_translation.display.translated",
            selection: Binding(
                get: { viewModel.configuration.renderMode },
                set: viewModel.setRenderMode
            )
        ) {
            Text("in_place_screenshot_translation.display.original")
                .tag(InPlaceTranslationRenderMode.original)
            Text("in_place_screenshot_translation.display.translated")
                .tag(InPlaceTranslationRenderMode.translated)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private func errorText(_ category: InPlaceTranslationErrorCategory) -> some View {
        switch category {
        case .permission:
            Text("in_place_screenshot_translation.error.permission")
        case .displayDisconnected:
            Text("in_place_screenshot_translation.error.display_disconnected")
        case .selectionTooLarge:
            Text("in_place_screenshot_translation.error.selection_too_large")
        case .authentication:
            Text("in_place_screenshot_translation.error.authentication")
        case .unsupportedLanguage:
            Text("in_place_screenshot_translation.error.unsupported_language")
        case .rateLimited:
            Text("in_place_screenshot_translation.error.rate_limited")
        case .network:
            Text("in_place_screenshot_translation.error.network")
        case .serviceUnavailable:
            Text("in_place_screenshot_translation.error.service_unavailable")
        case .noText:
            Text("in_place_screenshot_translation.status.no_text")
        case .capture:
            Text("in_place_screenshot_translation.error.capture")
        case .unknown:
            Text("in_place_screenshot_translation.error.ocr")
        }
    }
}
