//
//  ServiceConfigurationSecretSectionView.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/31.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import SwiftUI

// MARK: - ServiceConfigurationSecretSectionView

struct ServiceConfigurationSecretSectionView<Content: View>: View {
    // MARK: Lifecycle

    init(
        service: QueryService,
        observeKeys: [Defaults.Key<String>],
        @ViewBuilder content: () -> Content
    ) {
        self.service = service
        self.content = content()
        self.viewModel = ServiceValidationViewModel(
            service: service,
            observing: observeKeys
        )
    }

    // MARK: Internal

    var service: QueryService
    let content: Content

    var header: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(service.name())
            Spacer()
        }
    }

    var footer: some View {
        HStack {
            if service.isDuplicatable() {
                Button {
                    service.duplicate()
                } label: {
                    Text("service.configuration.duplicate")
                }

                if service.isDeletable(service.windowType) {
                    Button("service.configuration.delete", role: .destructive) {
                        service.remove()
                    }
                }

                Spacer()
            }

            Button {
                validate()
            } label: {
                Group {
                    if viewModel.isValidating {
                        ProgressView()
                            .controlSize(.small)
                            .progressViewStyle(.circular)
                    } else {
                        Text("service.configuration.validate")
                    }
                }
            }
            .disabled(viewModel.isValidateBtnDisabled)
        }
    }

    var body: some View {
        Section {
            content
        } header: {
            header
        } footer: {
            footer
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.isAlertPresented) {
            Button("ok") {
                viewModel.reset()
            }
        } message: {
            Text(viewModel.errorMessage.prefix(1000))
        }
        .onDisappear {
            viewModel.invalidate()
        }
    }

    func validate() {
        viewModel.isValidating.toggle()

        Task {
            do {
                let result = await service.validate()

                if let error = result.error {
                    throw error
                }

                guard viewModel.isValidating else { return }

                guard let translatedText = result.translatedText, !translatedText.isEmpty else {
                    throw QueryError(type: .api, message: "Empty result text")
                }

                viewModel.alertTitle = "service.configuration.validation_success"
                viewModel.errorMessage = result.errorMessage ?? ""

            } catch {
                viewModel.alertTitle = "service.configuration.validation_fail"
                viewModel.errorMessage = error.localizedDescription
            }

            viewModel.isValidating = false
            viewModel.isAlertPresented = true

            logInfo("\(service.serviceType().rawValue) validate \(viewModel.alertTitle)")
        }
    }

    // MARK: Private

    @ObservedObject private var viewModel: ServiceValidationViewModel
}

// MARK: - ServiceValidationViewModel

@MainActor
private class ServiceValidationViewModel: ObservableObject {
    // MARK: Lifecycle

    init(service: QueryService, observing keys: [Defaults.Key<String>]) {
        self.service = service
        self.name = service.name()

        // check secret key empty input
        Defaults.publisher(keys: keys)
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                let hasEmptyInput = keys.contains(where: { Defaults[$0].isEmpty })
                guard isValidateBtnDisabled != hasEmptyInput else { return }
                self.isValidateBtnDisabled = hasEmptyInput
            }
            .store(in: &cancellables)

        serviceUpdatePublisher
            .sink { [weak self] notification in
                self?.didReceive(notification)
            }
            .store(in: &cancellables)
    }

    // MARK: Internal

    @Published var isAlertPresented = false
    @Published var isValidating = false
    @Published var alertTitle: LocalizedStringKey = ""
    @Published var errorMessage = ""
    @Published var isValidateBtnDisabled = false

    var cancellables: Set<AnyCancellable> = []

    let service: QueryService

    @Published var name = ""

    func invalidate() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    func reset() {
        isValidating = false
        alertTitle = ""
        errorMessage = ""
        isAlertPresented = false
    }

    // MARK: Private

    private var serviceUpdatePublisher: AnyPublisher<Notification, Never> {
        NotificationCenter.default
            .publisher(for: .serviceHasUpdated)
            .eraseToAnyPublisher()
    }

    private func didReceive(_ notification: Notification) {
        guard let info = notification.userInfo as? [String: Any] else { return }
        guard let serviceType = info[EZServiceTypeKey] as? String else { return }
        guard serviceType == service.serviceType().rawValue else { return }
        name = service.name()
    }
}

#Preview {
    ServiceConfigurationSecretSectionView(service: EZBingService(), observeKeys: [.bingCookieKey]) {
        SecureInputCell(
            textFieldTitleKey: "service.configuration.bing.cookie.title",
            key: .bingCookieKey
        )
    }
}
