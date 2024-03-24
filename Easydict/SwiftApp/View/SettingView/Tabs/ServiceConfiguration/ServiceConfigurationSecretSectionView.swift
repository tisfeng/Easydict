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

@available(macOS 13.0, *)
struct ServiceConfigurationSecretSectionView<Content: View>: View {
    var service: QueryService
    let content: Content

    @StateObject private var viewModel: ServiceValidationViewModel

    init(
        service: QueryService,
        observeKeys: [Defaults.Key<String?>],
        @ViewBuilder content: () -> Content
    ) {
        self.service = service
        self.content = content()
        _viewModel = .init(wrappedValue: ServiceValidationViewModel(observing: observeKeys))
    }

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
        .alert(viewModel.alertMessage, isPresented: $viewModel.isAlertPresented) {
            Button("ok") {
                viewModel.reset()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    func validate() {
        viewModel.isValidating.toggle()
        service.validate { _, error in
            DispatchQueue.main.async {
                guard viewModel.isValidating else { return }

                viewModel.isValidating = false
                viewModel.alertMessage = "service.configuration.validation_success"

                if let error {
                    viewModel.alertMessage = "service.configuration.validation_fail"
                    viewModel.errorMessage = error.localizedDescription
                }

                print("\(service.serviceType().rawValue) validate \(error == nil ? "success" : "fail")!")
                viewModel.isAlertPresented = true
            }
        }
    }
}

@MainActor
private class ServiceValidationViewModel: ObservableObject {
    @Published var isAlertPresented = false
    @Published var isValidating = false
    @Published var alertMessage: LocalizedStringKey = ""
    @Published var errorMessage = ""

    @Published var isValidateBtnDisabled = false

    var cancellables: [AnyCancellable] = []

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

    func reset() {
        isValidating = false
        alertMessage = ""
        errorMessage = ""
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
