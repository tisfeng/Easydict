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
            List(selection: $selectedService) {
                WindowTypePicker(windowType: $windowType)
                ServiceItems(windowType: windowType)
            }
            .frame(maxWidth: 300)
            .listStyle(.sidebar)
            .scrollIndicators(.hidden)
            Group {
                if let service = selectedService {
                    Text(service.name())
                } else {
                    VStack {
                        Text("setting.service.detail.no_selection")
                    }
                }
            }
            .frame(width: 500)
        }
        .onChange(of: windowType) { _ in
            selectedService = nil
        }
    }
}

@available(macOS 13.0, *)
private struct ServiceItems: View {
    let windowType: EZWindowType

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
            ServiceItemView(service: service, windowType: windowType)
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

    init(service: QueryService, windowType: EZWindowType) {
        _service = .init(wrappedValue: .init(queryService: service, windowType: windowType))
    }

    var body: some View {
        Toggle(isOn: $service.enabled) {
            Label {
                Text(service.inner.name())
            } icon: {
                Image(service.inner.serviceType().rawValue)
                    .resizable()
                    .scaledToFit()
            }
        }
        .toggleStyle(.switch)
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
        Picker("", selection: $windowType) {
            ForEach([EZWindowType]([.mini, .fixed, .main]), id: \.rawValue) { windowType in
                Text(windowType.localizedStringResource)
                    .tag(windowType)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct SplitView<S: View, C: View>: View {
    @ViewBuilder let sidebar: () -> S
    @ViewBuilder let content: () -> C

    var body: some View {
        HStack {
            sidebar()
            content()
        }
    }
}
