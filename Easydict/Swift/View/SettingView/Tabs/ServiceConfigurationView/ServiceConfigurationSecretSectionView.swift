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
        self._viewModel = StateObject(wrappedValue: ServiceValidationViewModel(
            service: service,
            observing: observeKeys
        ))
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
            Text(viewModel.errorMessage)
        }
        .onDisappear {
            viewModel.invalidate()
        }
    }

    func validate() {
        viewModel.isValidating.toggle()
        service.validate { result, error in
            DispatchQueue.main.async {
                guard viewModel.isValidating else { return }

                var error = error

                // If error is nil but result text is also empty, we should report error.
                if error == nil, (result.translatedText?.isEmpty) == nil {
                    error = EZError(type: .API)
                }

                viewModel.isValidating = false
                viewModel
                    .alertTitle = (error == nil)
                    ? "service.configuration.validation_success"
                    : "service.configuration.validation_fail"

                result.error = EZError(nsError: error)
                viewModel.errorMessage = result.errorMessage ?? ""
                viewModel.isAlertPresented = true

                logInfo("\(service.serviceType().rawValue) validate \(error == nil ? "success" : "fail")!")
            }
        }
    }

    // MARK: Private

    @StateObject private var viewModel: ServiceValidationViewModel
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
        ServiceConfigurationSecureInputCell(
            textFieldTitleKey: "service.configuration.bing.cookie.title",
            key: .bingCookieKey
        )
    }
}
