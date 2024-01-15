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
    @State private var windowType = EZWindowType.mini
    @State private var selectedService: QueryService?

    var body: some View {
        HStack {
            VStack {
                WindowTypePicker(windowType: $windowType)
                    .padding()
                List {
                    ServiceItems(windowType: windowType, selectedService: $selectedService)
                }
                .scrollContentBackground(.hidden)
                .listItemTint(Color("service_cell_highlight"))
                .listStyle(.plain)
                .scrollIndicators(.never)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                .padding(.bottom)
                .padding(.horizontal)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            Group {
                if let service = selectedService {
                    // To provide configuration options for a service, follow these steps
                    // 1. If the Service is an object of Objc, expose it to Swift.
                    // 2. Create a new file in the Utility - Extensions - QueryService+ConfigurableService,
                    // 3. referring to OpenAIService+ConfigurableService, `extension` the Service as `ConfigurableService` to provide the configuration items.
                    if let service = service as? (any ConfigurableService) {
                        AnyView(service.configurationView())
                    } else {
                        // No configuration for service xxx
                        Text("setting.service.detail.no_configuration \(service.name())")
                    }
                } else {
                    VStack {
                        Text("setting.service.detail.no_selection")
                    }
                }
            }
            .frame(minWidth: 500)
        }
        .onChange(of: windowType) { _ in
            selectedService = nil
        }
    }
}

@available(macOS 13.0, *)
private struct ServiceItems: View {
    let windowType: EZWindowType
    @Binding var selectedService: QueryService?

    private var services: [QueryService] {
        EZLocalStorage.shared().allServices(windowType)
    }

    private var servicesWithID: [(QueryService, String)] {
        services.map { service in
            (service, "\(service.name())\(windowType)")
        }
    }

    var body: some View {
        ForEach(servicesWithID, id: \.1) { service, _ in
            ServiceItemView(service: service, windowType: windowType, selectedService: $selectedService)
                .tag(service)
        }
        .onMove(perform: onServiceItemMove)
    }

    private func onServiceItemMove(fromOffsets: IndexSet, toOffset: Int) {
        var services = services

        services.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let serviceTypes = services.map { service in
            service.serviceType()
        }

        EZLocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)

        postUpdateServiceNotification()

        // Trigger rerender to update view with new position
        refresh.objectWillChange.send()
    }

    private func postUpdateServiceNotification() {
        let userInfo: [String: Any] = [EZWindowTypeKey: windowType.rawValue]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }

    private class RefreshObservableObject: ObservableObject {}
    @StateObject private var refresh: RefreshObservableObject = .init()
}

@available(macOS 13.0, *)
private struct ServiceItemView: View {
    @StateObject private var service: QueryServiceWrapper

    @Binding private var selectedService: QueryService?

    init(service: QueryService, windowType: EZWindowType, selectedService: Binding<QueryService?>) {
        _service = .init(wrappedValue: .init(queryService: service, windowType: windowType))
        _selectedService = selectedService
    }

    var body: some View {
        Toggle(isOn: $service.enabled) {
            HStack {
                Image(service.inner.serviceType().rawValue)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20.0, height: 20.0)
                Text(service.inner.name())
            }
            .onTapGesture {
                selectedService = service.inner
            }
        }
        .padding(4.0)
        .toggleStyle(.switch)
        .controlSize(.small)
        .listRowSeparator(.hidden)
        .listRowBackground(selectedService == service.inner ? Color("service_cell_highlight") : Color.clear)
        .listRowInsets(.init())
        .padding(10)
        .background {
            if selectedService != service.inner {
                Color.white.onTapGesture {
                    selectedService = service.inner
                }
            }
        }
    }

    private class QueryServiceWrapper: ObservableObject {
        let windowType: EZWindowType
        var inner: QueryService

        var enabled: Bool {
            get {
                inner.enabled
            } set {
                inner.enabled = newValue
                if newValue {
                    inner.enabledQuery = newValue
                }
                save()
            }
        }

        private var cancellables: Set<AnyCancellable> = []

        init(queryService: QueryService, windowType: EZWindowType) {
            inner = queryService
            self.windowType = windowType

            enabled = queryService.enabled
        }

        private func save() {
            EZLocalStorage.shared().setService(inner, windowType: windowType)
            postUpdateServiceNotification()
        }

        private func postUpdateServiceNotification() {
            let userInfo: [String: Any] = [EZWindowTypeKey: windowType.rawValue]
            let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
            NotificationCenter.default.post(notification)
        }
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
