//
//  ConfigurationBackupSection.swift
//  Easydict
//
//  Created by Eric Pan on 2026/8/26.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - ConfigurationBackupSection

/// Password-encrypted configuration backup controls shown in Privacy settings.
struct ConfigurationBackupSection: View {
    // MARK: Internal

    var body: some View {
        Section {
            HStack {
                Button("configuration.backup.export.action") {
                    activeSheet = .exportPassword
                }
                Button("configuration.backup.import.action") {
                    chooseImportFile()
                }
            }
        } header: {
            Text("configuration.backup.section.title")
        } footer: {
            Text("configuration.backup.section.description")
                .font(.footnote)
        }
        .onAppear(perform: consumePendingSchemeAction)
        .onReceive(schemeActionCoordinator.$pendingAction) { action in
            if action == .encryptedExport {
                consumePendingSchemeAction()
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .exportPassword:
                ConfigurationBackupExportPasswordView(
                    onCancel: { activeSheet = nil },
                    onExport: beginExport
                )
            case let .importPassword(data):
                ConfigurationBackupImportPasswordView(
                    onCancel: { activeSheet = nil },
                    onImport: { password in prepareImport(data: data, password: password) }
                )
            case let .preview(preparedRestore):
                ConfigurationBackupPreviewView(
                    preparedRestore: preparedRestore,
                    onCancel: { activeSheet = nil },
                    onRestore: { apply(preparedRestore) }
                )
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert.kind {
            case .restored:
                Alert(
                    title: Text("configuration.backup.restore.success.title"),
                    message: Text("configuration.backup.restore.success.message"),
                    primaryButton: .destructive(Text("quit")) { NSApp.terminate(nil) },
                    secondaryButton: .cancel(Text("configuration.backup.restore.later"))
                )
            case .exported:
                Alert(
                    title: Text("configuration.backup.export.success.title"),
                    message: Text("configuration.backup.export.success.message"),
                    dismissButton: .default(Text("ok"))
                )
            case let .error(message):
                Alert(
                    title: Text("configuration.backup.error.title"),
                    message: Text(message),
                    dismissButton: .default(Text("ok"))
                )
            }
        }
    }

    // MARK: Private

    @State private var activeSheet: ConfigurationBackupSheet?
    @State private var activeAlert: ConfigurationBackupAlert?
    @ObservedObject private var schemeActionCoordinator = ConfigurationSchemeActionCoordinator.shared

    private let service = ConfigurationBackupService()

    private func consumePendingSchemeAction() {
        guard schemeActionCoordinator.pendingAction == .encryptedExport else { return }
        activeSheet = .exportPassword
        schemeActionCoordinator.consume(.encryptedExport)
    }

    private func beginExport(password: String, confirmation: String) {
        activeSheet = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = ConfigurationBackupService.suggestedFilename()
            panel.canCreateDirectories = true
            if let backupType = UTType(filenameExtension: "easydictbackup") {
                panel.allowedContentTypes = [backupType]
            }
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                performInBackground {
                    try service.writeBackup(password: password, confirmation: confirmation, to: url)
                } completion: { result in
                    switch result {
                    case .success:
                        activeAlert = .init(kind: .exported)
                    case let .failure(error):
                        present(error)
                    }
                }
            }
        }
    }

    private func chooseImportFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if let backupType = UTType(filenameExtension: "easydictbackup") {
            panel.allowedContentTypes = [backupType]
        }
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                activeSheet = .importPassword(try service.readBackup(at: url))
            } catch {
                present(error)
            }
        }
    }

    private func prepareImport(data: Data, password: String) {
        activeSheet = nil
        performInBackground {
            try service.prepareRestore(data: data, password: password)
        } completion: { result in
            switch result {
            case let .success(preparedRestore):
                activeSheet = .preview(preparedRestore)
            case let .failure(error):
                present(error)
            }
        }
    }

    private func apply(_ preparedRestore: PreparedConfigurationRestore) {
        activeSheet = nil
        do {
            try service.apply(preparedRestore)
            activeAlert = .init(kind: .restored)
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        activeAlert = .init(kind: .error(message))
    }

    private func performInBackground<T>(
        _ operation: @escaping () throws -> T,
        completion: @escaping (Result<T, Error>) -> ()
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { try operation() }
            DispatchQueue.main.async { completion(result) }
        }
    }
}

// MARK: - ConfigurationBackupSheet

private enum ConfigurationBackupSheet: Identifiable {
    case exportPassword
    case importPassword(Data)
    case preview(PreparedConfigurationRestore)

    // MARK: Internal

    var id: Int {
        switch self {
        case .exportPassword: 0
        case .importPassword: 1
        case .preview: 2
        }
    }
}

// MARK: - ConfigurationBackupAlert

private struct ConfigurationBackupAlert: Identifiable {
    enum Kind {
        case exported
        case restored
        case error(String)
    }

    let id = UUID()
    let kind: Kind
}

// MARK: - ConfigurationBackupExportPasswordView

private struct ConfigurationBackupExportPasswordView: View {
    // MARK: Internal

    let onCancel: () -> ()
    let onExport: (String, String) -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("configuration.backup.export.password.title").font(.headline)
            SecureField("configuration.backup.password.label", text: $password)
            SecureField("configuration.backup.password.confirm", text: $confirmation)
            Text("configuration.backup.password.warning")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("cancel", role: .cancel, action: cancel)
                Button("configuration.backup.export.confirm") {
                    let password = password
                    let confirmation = confirmation
                    clearPasswords()
                    onExport(password, confirmation)
                }
                .disabled(!canExport)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
        .onDisappear(perform: clearPasswords)
    }

    // MARK: Private

    @State private var password = ""
    @State private var confirmation = ""

    private var canExport: Bool {
        password.count >= ConfigurationBackupService.minimumPasswordLength && password == confirmation
    }

    private func cancel() {
        clearPasswords()
        onCancel()
    }

    private func clearPasswords() {
        password = ""
        confirmation = ""
    }
}

// MARK: - ConfigurationBackupImportPasswordView

private struct ConfigurationBackupImportPasswordView: View {
    // MARK: Internal

    let onCancel: () -> ()
    let onImport: (String) -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("configuration.backup.import.password.title").font(.headline)
            SecureField("configuration.backup.password.label", text: $password)
            HStack {
                Spacer()
                Button("cancel", role: .cancel, action: cancel)
                Button("configuration.backup.import.decrypt") {
                    let password = password
                    self.password = ""
                    onImport(password)
                }
                .disabled(password.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
        .onDisappear { password = "" }
    }

    // MARK: Private

    @State private var password = ""

    private func cancel() {
        password = ""
        onCancel()
    }
}

// MARK: - ConfigurationBackupPreviewView

private struct ConfigurationBackupPreviewView: View {
    // MARK: Internal

    let preparedRestore: PreparedConfigurationRestore
    let onCancel: () -> ()
    let onRestore: () -> ()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("configuration.backup.preview.title").font(.headline)
            previewRow("configuration.backup.preview.settings", preparedRestore.preview.settingCount)
            previewRow("configuration.backup.preview.credentials", preparedRestore.preview.credentialCount)
            previewRow("configuration.backup.preview.new", preparedRestore.preview.newCount)
            previewRow("configuration.backup.preview.overwrite", preparedRestore.preview.overwriteCount)
            previewRow(
                "configuration.backup.preview.skipped_endpoints",
                preparedRestore.preview.skippedUnsafeEndpointCount
            )
            Divider()
            Text("configuration.backup.preview.credentials_hidden")
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("cancel", role: .cancel, action: onCancel)
                Button("configuration.backup.restore.confirm", role: .destructive, action: onRestore)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    // MARK: Private

    private func previewRow(_ key: String.LocalizationValue, _ count: Int) -> some View {
        HStack {
            Text(String(localized: key))
            Spacer()
            Text(verbatim: count.formatted())
        }
    }
}
