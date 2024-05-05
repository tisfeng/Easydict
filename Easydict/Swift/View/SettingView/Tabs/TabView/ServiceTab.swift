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

@available(macOS 13, *)
struct ServiceTab: View {
    // MARK: Internal

    var body: some View {
        HStack {
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
            }

            Group {
                if let service = viewModel.selectedService {
                    // To provide configuration options for a service, follow these steps
                    // 1. If the Service is an object of Objc, expose it to Swift.
                    // 2. Create a new file in the Utility - Extensions - QueryService+ConfigurableService,
                    // 3. referring to OpenAIService+ConfigurableService, `extension` the Service
                    // as `ConfigurableService` to provide the configuration items.
                    if let service = service as? (any ConfigurableService) {
                        AnyView(service.configurationView())
                    } else {
                        HStack {
                            Spacer()
                            // No configuration for service xxx
                            Text("setting.service.detail.no_configuration \(service.name())")
                            Spacer()
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("setting.service.detail.no_selection")
                        Spacer()
                    }
                }
            }
            .layoutPriority(1)
        }
        .environmentObject(viewModel)
    }

    // MARK: Private

    @StateObject private var viewModel: ServiceTabViewModel = .init()
}

// MARK: - ServiceTabViewModel

private class ServiceTabViewModel: ObservableObject {
    @Published var selectedService: QueryService?

    @Published private(set) var services: [QueryService] = EZLocalStorage.shared().allServices(.mini)

    @Published var windowType = EZWindowType.mini {
        didSet {
            if oldValue != windowType {
                updateServices()
                selectedService = nil
            }
        }
    }

    func updateServices() {
        services = getServices()
    }

    func getServices() -> [QueryService] {
        EZLocalStorage.shared().allServices(windowType)
    }

    func onServiceItemMove(fromOffsets: IndexSet, toOffset: Int) {
        var services = services

        services.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = services.map { service in
            service.serviceType()
        }

        EZLocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)

        postUpdateServiceNotification()

        updateServices()
    }

    func postUpdateServiceNotification() {
        let userInfo: [String: Any] = [EZWindowTypeKey: windowType.rawValue]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
}

// MARK: - ServiceItems

@available(macOS 13.0, *)
private struct ServiceItems: View {
    // MARK: Internal

    var body: some View {
        ForEach(servicesWithID, id: \.1) { service, _ in
            ServiceItemView(service: service)
                .tag(service)
        }
        .onMove(perform: viewModel.onServiceItemMove)
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var servicesWithID: [(QueryService, String)] {
        viewModel.services.map { service in
            (service, service.serviceType().rawValue)
        }
    }
}

// MARK: - ServiceItemViewModel

private class ServiceItemViewModel: ObservableObject {
    // MARK: Lifecycle

    init(_ service: QueryService) {
        self.service = service
        self.isEnable = service.enabled
        self.name = service.name()

        cancellables.append(
            serviceUpdatePublisher
                .sink { [weak self] notification in
                    self?.didReceive(notification)
                }
        )
    }

    // MARK: Internal

    let service: QueryService

    @Published var isEnable = false
    @Published var name = ""

    // MARK: Private

    private var cancellables: [AnyCancellable] = []

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

@available(macOS 13.0, *)
private struct ServiceItemView: View {
    // MARK: Lifecycle

    init(service: QueryService) {
        self.service = service
        self.serviceItemViewModel = ServiceItemViewModel(service)
    }

    // MARK: Internal

    let service: QueryService

    var body: some View {
        Toggle(isOn: $serviceItemViewModel.isEnable) {
            HStack {
                Image(service.serviceType().rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20.0, height: 20.0)
                Text(service.name())
                    .lineLimit(1)
            }
        }
        .onReceive(serviceItemViewModel.$isEnable) { newValue in
            guard service.enabled != newValue else { return }
            service.enabled = newValue
            if newValue {
                service.enabledQuery = newValue
            }
            EZLocalStorage.shared().setService(service, windowType: viewModel.windowType)
            viewModel.postUpdateServiceNotification()
            // check enable state in case of state not changed while saving
            service.enabled = EZLocalStorage.shared().service(
                service.serviceType(),
                windowType: viewModel.windowType
            ).enabled
            serviceItemViewModel.isEnable = service.enabled
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .listRowSeparator(.hidden)
        .listRowInsets(.init())
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    @ObservedObject private var serviceItemViewModel: ServiceItemViewModel
}

// MARK: - WindowTypePicker

@available(macOS 13, *)
private struct WindowTypePicker: View {
    @Binding var windowType: EZWindowType

    var body: some View {
        Picker(selection: $windowType) {
            ForEach([EZWindowType]([.mini, .fixed, .main]), id: \.rawValue) { windowType in
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
