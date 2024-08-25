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
                .onReceive(serviceHasUpdatedPub) { _ in
                    viewModel.updateServices()
                }
            }

            Group {
                if let service = viewModel.selectedService {
                    if let view = service.configurationListItems() as? (any View) {
                        Form {
                            AnyView(view)
                        }
                        .formStyle(.grouped)

                    } else {
                        HStack {
                            Spacer()
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

    private let serviceHasUpdatedPub = NotificationCenter.default
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

        let isSelectedExist = services
            .contains { $0.serviceType() == selectedService?.serviceType() && $0.uuid == selectedService?.uuid }
        if !isSelectedExist {
            selectedService = nil
        }
    }

    func onServiceItemMove(fromOffsets: IndexSet, toOffset: Int) {
        var services = services
        services.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = services.map { service in
            "\(service.serviceType())#\(service.uuid)"
        }
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
            ServiceItemView(service: service)
                .tag(service)
        }
        .onMove(perform: viewModel.onServiceItemMove)
    }

    // MARK: Private

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var servicesWithID: [(QueryService, Int)] {
        viewModel.services.enumerated().map { index, service in
            (service, index)
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
