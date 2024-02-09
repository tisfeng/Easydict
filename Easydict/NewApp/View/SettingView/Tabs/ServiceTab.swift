//
//  ServiceTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import SwiftUI

@available(macOS 13, *)
struct ServiceTab: View {
    @StateObject private var viewModel: ServiceTabViewModel = .init()

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
            }
            Group {
                if let service = viewModel.selectedService {
                    // To provide configuration options for a service, follow these steps
                    // 1. If the Service is an object of Objc, expose it to Swift.
                    // 2. Create a new file in the Utility - Extensions - QueryService+ConfigurableService,
                    // 3. referring to OpenAIService+ConfigurableService, `extension` the Service as `ConfigurableService` to provide the configuration items.
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
}

private class ServiceTabViewModel: ObservableObject {
    @Published var windowType = EZWindowType.mini {
        didSet {
            if oldValue != windowType {
                updateServices()
                selectedService = nil
            }
        }
    }

    @Published var selectedService: QueryService?

    @Published private(set) var services: [QueryService] = EZLocalStorage.shared().allServices(.mini)

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

@available(macOS 13.0, *)
private struct ServiceItems: View {
    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var servicesWithID: [(QueryService, String)] {
        viewModel.services.map { service in
            (service, service.name())
        }
    }

    var body: some View {
        ForEach(servicesWithID, id: \.1) { service, _ in
            ServiceItemView(service: service)
                .tag(service)
        }
        .onMove(perform: viewModel.onServiceItemMove)
    }
}

@available(macOS 13.0, *)
private struct ServiceItemView: View {
    let service: QueryService

    @EnvironmentObject private var viewModel: ServiceTabViewModel

    private var enabled: Binding<Bool> {
        .init {
            service.enabled
        } set: { newValue in
            guard service.enabled != newValue else { return }
            service.enabled = newValue
            if newValue {
                service.enabledQuery = newValue
            }
            EZLocalStorage.shared().setService(service, windowType: viewModel.windowType)
            viewModel.postUpdateServiceNotification()
        }
    }

    var body: some View {
        Toggle(isOn: enabled) {
            HStack {
                Image(service.serviceType().rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20.0, height: 20.0)
                Text(service.name())
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(4.0)
        .toggleStyle(.switch)
        .controlSize(.small)
        .listRowSeparator(.hidden)
        .listRowInsets(.init())
        .padding(10)
    }
}

@available(macOS 13, *)
private struct WindowTypePicker: View {
    @Binding var windowType: EZWindowType

    var body: some View {
        HStack {
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
}
