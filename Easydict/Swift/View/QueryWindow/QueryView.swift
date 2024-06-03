//
//  QueryWindow.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/6/2.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// MARK: - QueryView

@available(macOS 13.0, *)
struct QueryView: View {
    // MARK: Lifecycle

    init() {
        self._viewModel = .init(wrappedValue: QueryViewModel(textToTranslate: ""))
    }

    // MARK: Internal

    var body: some View {
        List {
            TextField("Text to Translate", text: $viewModel.textToTranslate, axis: .vertical)
                .autocorrectionDisabled()
                .border(.black, width: 1)
                .onSubmit {
                    viewModel.doTranslate()
                }
            HStack {
                Picker(selection: $viewModel.fromLanguage) {
                    Text(verbatim: "🌐 Auto")
                        .tag(Language.auto)
                    ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                        Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                            .tag(option)
                    }
                } label: {
                    EmptyView()
                }
                Picker(selection: $viewModel.toLanguage) {
                    Text(verbatim: "🌐 Auto")
                        .tag(Language.auto)
                    ForEach(Language.allAvailableOptions, id: \.rawValue) { option in
                        Text(verbatim: "\(option.flagEmoji) \(option.localizedName)")
                            .tag(option)
                    }
                } label: {
                    EmptyView()
                }
            }
            ForEach(viewModel.services.map { service in
                (service, service.serviceType().rawValue)
            }, id: \.1) { service, _ in
                QueryResultView(service: service)
            }
        }
        .environmentObject(viewModel)
    }

    // MARK: Private

    @StateObject private var viewModel: QueryViewModel
}

// MARK: - QueryViewModel

class QueryViewModel: ObservableObject {
    // MARK: Lifecycle

    init(textToTranslate: String) {
        self.textToTranslate = textToTranslate
        self.fromLanguage = .auto
        self.toLanguage = .auto
        let windowType: EZWindowType = .mini
        self.windowType = windowType
        self.services = EZLocalStorage.shared().allServices(windowType).filter { service in
            service.enabled
        }
    }

    // MARK: Internal

    @Published var textToTranslate: String

    @Published var fromLanguage: Language
    @Published var toLanguage: Language

    @Published var windowType: EZWindowType

    // TODO: listen updating service
    @Published var services: [QueryService]

    var callbacks: [() -> ()] = []

    let doTranslateSignal: PassthroughSubject<(), Never> = .init()

    func doTranslate() {
        doTranslateSignal.send(())
    }
}

// MARK: - QueryResultView

private struct QueryResultView: View {
    @EnvironmentObject private var queryViewModel: QueryViewModel

    let service: QueryService

    @State var result: Result<EZQueryResult, Error>?

    var body: some View {
        VStack(alignment: .leading) {
            Text(service.name())
            switch result {
            case let .success(queryResult):
                if queryResult.isLoading {
                    ProgressView()
                } else {
                    Text(queryResult.translatedText ?? "🌐")
                }
            case let .failure(error):
                Text(error.localizedDescription)
            case nil:
                EmptyView()
            }
        }
        .onReceive(queryViewModel.doTranslateSignal, perform: { _ in
            doTranslate()
        })
    }

    func doTranslate() {
        Task {
            do {
                result = .success(try await service.translate(
                    queryViewModel.textToTranslate,
                    from: queryViewModel.fromLanguage,
                    to: queryViewModel.toLanguage
                ))
            } catch {
                result = .failure(error)
            }
        }
    }
}
