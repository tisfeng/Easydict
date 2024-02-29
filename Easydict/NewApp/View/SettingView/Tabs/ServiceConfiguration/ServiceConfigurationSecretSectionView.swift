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

@available(macOS 13.0, *)
struct ServiceConfigurationSecretSectionView<Content: View>: View {
    // MARK: Lifecycle

    init(
        service: QueryService,
        observeKeys: [Defaults.Key<String?>],
        @ViewBuilder content: () -> Content
    ) {
        self.service = service
        self.content = content()
        _viewModel = .init(wrappedValue: ServiceValidationViewModel(observing: observeKeys))
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
        .alert(viewModel.alertMessage, isPresented: $viewModel.isAlertPresented, actions: {
            Button("ok") {
                viewModel.reset()
            }
        })
    }

    func validate() {
        viewModel.isValidating.toggle()
        service.validate { _, error in
            DispatchQueue.main.async {
                guard viewModel.isValidating else { return }
                viewModel.isValidating = false
                viewModel
                    .alertMessage = error == nil ? "service.configuration.validation_success" :
                    "service.configuration.validation_fail"
                print("\(service.serviceType()) validate \(error == nil ? "success" : "fail")!")
                viewModel.isAlertPresented = true
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

    init(observing keys: [Defaults.Key<String?>]) {
        cancellables.append(
            // check secret key empty input
            Defaults.publisher(keys: keys)
                .sink { [weak self] _ in
                    let hasEmptyInput = keys.contains(where: { (Defaults[$0] ?? "").isEmpty })
                    DispatchQueue.main.async {
                        self?.isValidateBtnDisabled = hasEmptyInput
                    }
                }
        )
    }

    // MARK: Internal

    @Published var isAlertPresented = false

    @Published var isValidating = false

    @Published var alertMessage: LocalizedStringKey = ""

    @Published var isValidateBtnDisabled = false

    var cancellables: [AnyCancellable] = []

    func reset() {
        isValidating = false
        alertMessage = ""
        isAlertPresented = false
    }
}

@available(macOS 13.0, *)
#Preview {
    ServiceConfigurationSecretSectionView(service: EZBingService(), observeKeys: [.bingCookieKey]) {
        ServiceConfigurationSecureInputCell(
            textFieldTitleKey: "service.configuration.bing.cookie.title",
            key: .bingCookieKey
        )
    }
}
