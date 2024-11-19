//
//  ServiceTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import SwiftUI

// MARK: - ServiceTab

struct ServiceTab: View {
    // MARK: Internal

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack {
                WindowTypePicker(windowType: $viewModel.windowType)
                    .padding()
                List(selection: $viewModel.selectedService) {
                    ServiceItems()
                }
                .listStyle(.plain)
                .scrollIndicators(.never)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.bottom)
                .padding(.horizontal)
                .frame(minWidth: 260)
                .onReceive(serviceHasUpdatedNotification) { _ in
                    viewModel.updateServices()
                }
            }

            Group {
                if let service = viewModel.selectedService {
                    VStack(alignment: .leading) {
                        Button("setting.service.back") {
                            viewModel.selectedService = nil
                        }
                        .padding()

                        if let view = service.configurationListItems() as? (any View) {
                            Form {
                                AnyView(view)
                            }
                            .formStyle(.grouped)
                        } else {
                            Spacer()
                            HStack {
                                Spacer()
                                Text("setting.service.detail.no_configuration \(service.name())")
                                Spacer()
                            }
                            Spacer()
                        }
                    }
                } else {
                    WindowConfigurationView(windowType: viewModel.windowType)
                }
            }
            .layoutPriority(1)
        }
        .environmentObject(viewModel)
    }

    // MARK: Private

    private let serviceHasUpdatedNotification = NotificationCenter.default
        .publisher(for: .serviceHasUpdated)

    @StateObject private var viewModel: ServiceTabViewModel = .init()
}

// MARK: - ServiceTabViewModel

private class ServiceTabViewModel: ObservableObject {
    // MARK: Lifecycle

    init(windowType: EZWindowType = .fixed) {
        self.windowType = windowType
        self.services = EZLocalStorage.shared().allServices(windowType)
    }

    // MARK: Internal

    @Published var selectedService: QueryService?

    @Published private(set) var services: [QueryService]

    @Published var windowType: EZWindowType {
        didSet {
            if oldValue != windowType {
                updateServices()
                selectedService = nil
            }
        }
    }

    func updateServices() {
        services = EZLocalStorage.shared().allServices(windowType)

        let isSelectedExist =
            services
                .contains {
                    $0.serviceTypeWithUniqueIdentifier()
                        == selectedService?.serviceTypeWithUniqueIdentifier()
                }
        if !isSelectedExist {
            selectedService = nil
        }
    }

    func onServiceItemMove(fromOffsets: IndexSet, toOffset: Int) {
        var services = services
        services.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = services.map { $0.serviceTypeWithUniqueIdentifier() }
        EZLocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)

        postUpdateServiceNotification()
        updateServices()
    }

    func postUpdateServiceNotification() {
        NotificationCenter.default.postServiceUpdateNotification(windowType: windowType)
    }
}

// MARK: - ServiceItems

private struct ServiceItems: View {
    // MARK: Internal

    var body: some View {
        ForEach(servicesWithID, id: \.1) { service, _ in
            ServiceItemView(service: service, viewModel: viewModel)
                .tag(service)
        }
        .onMove(perform: viewModel.onServiceItemMove)
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var servicesWithID: [(QueryService, String)] {
        viewModel.services.map { service in
            (service, service.serviceTypeWithUniqueIdentifier())
        }
    }
}

// MARK: - ServiceItemViewModel

@MainActor
private class ServiceItemViewModel: ObservableObject {
    // MARK: Lifecycle

    init(_ service: QueryService, viewModel: ServiceTabViewModel) {
        self.service = service
        self.name = service.name()
        self.viewModel = viewModel

        cancellables.append(
            serviceUpdatePublisher
                .sink { [weak self] notification in
                    self?.didReceive(notification)
                }
        )
    }

    // MARK: Public

    public func enableService() {
        // filter
        if service.serviceType() == .appleDictionary ||
            service.serviceType() == .apple {
            service.enabled = true
            service.enabledQuery = true
            EZLocalStorage.shared().setService(service, windowType: viewModel.windowType)
            viewModel.postUpdateServiceNotification()
            return
        }

        isValidating = true

        service.validate { [self] result, error in
            // check into main thread
            DispatchQueue.main.async {
                defer { self.isValidating = false }
                // Validate existence error
                if let error = error {
                    logInfo("\(self.service.serviceType().rawValue) validate error: \(error)")
                    self.error = error
                    self.showErrorAlert = true
                    return
                }

                // If error is nil but result text is also empty, we should report error.
                guard let translatedText = result.translatedText, !translatedText.isEmpty else {
                    logInfo("\(self.service.serviceType().rawValue) validate translated text is empty")
                    self.showErrorAlert = true
                    self.error = EZError(
                        type: .API,
                        description: String(localized: "setting.service.validate.error.empty_translate_result")
                    )
                    return
                }

                // service enabel open the switch and toggle enable status
                self.service.enabled = true
                self.service.enabledQuery = true
                EZLocalStorage.shared().setService(self.service, windowType: self.viewModel.windowType)
                self.viewModel.postUpdateServiceNotification()
                self.objectWillChange.send()
            }
        }
    }

    // MARK: Internal

    let service: QueryService

    @Published var isValidating = false
    @Published var name = ""

    @Published var showErrorAlert = false
    @Published var error: (any Error)?

    unowned var viewModel: ServiceTabViewModel

    var isEnable: Bool {
        get {
            service.enabled
        } set {
            if newValue {
                // validate service enabled
                enableService()
            } else { // close service
                service.enabled = false
                EZLocalStorage.shared().setService(service, windowType: viewModel.windowType)
                viewModel.postUpdateServiceNotification()
            }
        }
    }

    // MARK: Private

    private var cancellables: [AnyCancellable] = []

    @EnvironmentObject private var serviceTabViewModel: ServiceTabViewModel

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

// MARK: - ServiceItemView

private struct ServiceItemView: View {
    // MARK: Lifecycle

    init(service: QueryService, viewModel: ServiceTabViewModel) {
        self.service = service
        self.serviceItemViewModel = ServiceItemViewModel(service, viewModel: viewModel)
    }

    // MARK: Internal

    let service: QueryService

    var body: some View {
        Group {
            HStack {
                HStack {
                    Image(service.serviceType().rawValue)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20.0, height: 20.0)
                    Text(service.name())
                        .lineLimit(1)
                }
                Spacer()
                if serviceItemViewModel.isValidating {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Toggle(serviceItemViewModel.service.name(), isOn: $serviceItemViewModel.isEnable)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowInsets(.init())
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .alert(
            "setting.service.unable_enable \(serviceItemViewModel.service.name())",
            isPresented: $serviceItemViewModel.showErrorAlert
        ) {
            Button("ok") {
                serviceItemViewModel.showErrorAlert = false
            }
        } message: {
            Text(serviceItemViewModel.error?.localizedDescription ?? "error_unknown")
        }
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    @ObservedObject private var serviceItemViewModel: ServiceItemViewModel
}

// MARK: - WindowTypePicker

private struct WindowTypePicker: View {
    @Binding var windowType: EZWindowType

    var body: some View {
        Picker(selection: $windowType) {
            ForEach([EZWindowType]([.fixed, .mini, .main]), id: \.rawValue) { windowType in
                Text(windowType.localizedStringResource)
                    .tag(windowType)
            }
        } label: {
            EmptyView()
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }
}
