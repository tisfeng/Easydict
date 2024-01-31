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

    @ObservedObject private var viewModel = ServiceValidationViewModel()

    init(
        service: QueryService,
        observeKeys: [Defaults.Key<String?>],
        @ViewBuilder content: () -> Content
    ) {
        self.service = service
        self.content = content()

        viewModel.observeInput(for: observeKeys)
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
        .alert(isPresented: $viewModel.isAlertAlertPresented) {
            Alert(title: Text(viewModel.alertMessage))
        }
    }

    func validate() {
        viewModel.isValidating.toggle()
        service.validate { _, error in
            viewModel.alertMessage = error == nil ? "service.configuration.validation_success" : "service.configuration.validation_fail"
            print("\(service.serviceType()) validate \(error == nil ? "success" : "fail")!")
            viewModel.isValidating.toggle()
            viewModel.isAlertAlertPresented.toggle()
        }
    }
}

private class ServiceValidationViewModel: ObservableObject {
    @Published var isAlertAlertPresented = false

    @Published var isValidating = false

    @Published var alertMessage: LocalizedStringKey = ""

    @Published var isValidateBtnDisabled = false

    var cancellables: [AnyCancellable] = []

    // check secret key empty input
    func observeInput(for keys: [Defaults.Key<String?>]) {
        cancellables.append(
            Defaults.publisher(keys: keys)
                .sink { [weak self] _ in
                    let hasEmptyInput = keys.contains(where: { (Defaults[$0] ?? "").isEmpty })
                    self?.isValidateBtnDisabled = hasEmptyInput
                }
        )
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
