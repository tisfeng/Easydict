//
//  CodexManagedAccountView.swift
//  Easydict
//
//  Created by Alfred on 2026/09/07.
//

import SwiftUI

/// Presents shared ChatGPT authentication without coupling it to query results.
/// Reopening the browser uses the existing authorization address; appearance only
/// refreshes status, while connection checks require login success or a button tap.
struct CodexManagedAccountView: View {
    // MARK: Internal

    let configuration: CodexServiceConfiguration

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("service.codex_cli.managed.description")
                .font(.caption)
                .foregroundStyle(.secondary)
            if !component.isReady {
                componentControls
            } else {
                HStack {
                    if account.isBusy { ProgressView().controlSize(.small) }
                    Text(status)
                    Spacer()
                    if account.isBusy {
                        Button("service.codex_cli.managed.cancel") { account.cancelCurrentOperation() }
                    } else if account.isSignedIn {
                        Button("service.codex_cli.managed.verify") { account.validate(configuration: configuration) }
                        Button("service.codex_cli.managed.logout") { account.logout() }
                    } else {
                        Button("service.codex_cli.managed.login") { account.login(origin: origin) }
                    }
                }
                if account.authorizationURL != nil {
                    Button("service.codex_cli.managed.reopen_browser") { account.reopenBrowser() }
                }
                if let message = account.errorMessage(for: configuration) {
                    Text(message).font(.caption).foregroundStyle(.red).textSelection(.enabled)
                    if !account.isBusy {
                        Button("service.codex_cli.managed.refresh") { component.refresh() }
                    }
                }
            }
        }
        .task {
            component.retainConsumer(origin)
            component.refreshIfNeeded()
            if component.isReady { account.refreshIfNeeded() }
        }
        .onChange(of: component.isReady) { ready in
            if ready { account.refresh() }
        }
    }

    // MARK: Private

    @ObservedObject private var component = CodexComponentManager.shared

    @ObservedObject private var account = CodexManagedAccount.shared

    private var origin: String { configuration.uuid }

    private var status: LocalizedStringKey {
        switch account.state {
        case .unknown: "service.codex_cli.managed.status.unknown"
        case .checking: "service.codex_cli.managed.status.checking"
        case .signedOut: "service.codex_cli.managed.status.signed_out"
        case .authorizing: "service.codex_cli.managed.status.authorizing"
        case .verifying: "service.codex_cli.managed.status.verifying"
        case .signedIn: "service.codex_cli.managed.status.signed_in"
        case .ready:
            account.isValidated(configuration: configuration)
                ? "service.codex_cli.managed.status.ready"
                : "service.codex_cli.managed.status.signed_in"
        }
    }

    @ViewBuilder private var componentControls: some View {
        HStack {
            switch component.state {
            case let .downloading(fraction):
                ProgressView(value: fraction).frame(width: 100)
                Text("service.codex_cli.component.downloading")
            case .installing:
                ProgressView().controlSize(.small)
                Text("service.codex_cli.component.installing")
            case .cancelling:
                Text("service.codex_cli.component.cancelling")
            case .checking, .unknown:
                Text("service.codex_cli.component.checking")
            case .failed, .missing:
                Text("service.codex_cli.component.missing")
            case .ready:
                EmptyView()
            }
            Spacer()
            if component.isBusy {
                Button("service.codex_cli.managed.cancel") { component.cancel() }
                    .disabled({ if case .cancelling = component.state { return true }; return false }())
            } else {
                Button("service.codex_cli.component.download") { component.download(origin: origin) }
            }
        }
        if let message = component.errorMessage {
            Text(message).font(.caption).foregroundStyle(.red).textSelection(.enabled)
        }
    }
}
