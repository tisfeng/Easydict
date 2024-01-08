//
//  ServiceTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

@available(macOS 13, *)
struct ServiceTab: View {
    @State private var windowTypeValue = EZWindowType.mini.rawValue
    @State private var serviceTypes: [ServiceType] = []
    @State private var services: [QueryService] = []
    @State private var selectedIndex: Int?

    var segmentCtrl: some View {
        Picker("", selection: $windowTypeValue) {
            Text("mini_window")
                .tag(EZWindowType.mini.rawValue)

            Text("fixed_window")
                .tag(EZWindowType.fixed.rawValue)

            Text("main_window")
                .tag(EZWindowType.main.rawValue)
        }
        .padding()
        .pickerStyle(.segmented)
        .onChange(of: windowTypeValue) { type in
            loadService(type: type)
        }
    }

    var serviceList: some View {
        List {
            ForEach(Array(serviceTypes.enumerated()), id: \.offset) { index, _ in
                ServiceItemView(
                    service: $services[index]
                ) { isEnable in
                    serviceToggled(index: index, isEnable: isEnable)
                }
                .tag(index)
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedIndex == nil || selectedIndex != index {
                        selectedIndex = index
                    } else {
                        selectedIndex = nil
                    }
                }
                .listRowBackground(selectedIndex == index ? Color("service_cell_highlight") : Color.clear)
            }
            .onMove(perform: { indices, newOffset in
                onServiceItemMove(fromOffsets: indices, toOffset: newOffset)
            })
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 8.0))
        .padding([.horizontal, .bottom])
    }

    var body: some View {
        VStack {
            segmentCtrl

            serviceList
        }
        .onAppear {
            loadService(type: windowTypeValue)
        }
    }

    func loadService(type: Int) {
        let windowType = EZWindowType(rawValue: type) ?? .none
        services = EZLocalStorage.shared().allServices(windowType)
        serviceTypes = services.map { service in
            service.serviceType()
        }
    }

    func serviceToggled(index: Int, isEnable: Bool) {
        let service = services[index]
        service.enabled = isEnable
        if isEnable {
            service.enabledQuery = true
        }
        let windowType = EZWindowType(rawValue: windowTypeValue) ?? .none
        EZLocalStorage.shared().setService(services[index], windowType: windowType)
        // refresh service list
        loadService(type: windowTypeValue)
        postUpdateServiceNotification()
    }

    func enabledServices(in services: [QueryService]) -> [QueryService] {
        services.filter(\.enabled)
    }

    func onServiceItemMove(fromOffsets: IndexSet, toOffset: Int) {
        let oldEnabledServices = enabledServices(in: services)

        services.move(fromOffsets: fromOffsets, toOffset: toOffset)
        serviceTypes.move(fromOffsets: fromOffsets, toOffset: toOffset)

        let windowType = EZWindowType(rawValue: windowTypeValue) ?? .none
        EZLocalStorage.shared().setAllServiceTypes(serviceTypes, windowType: windowType)
        let newServices = EZLocalStorage.shared().allServices(windowType)
        let newEnabledServices = enabledServices(in: newServices)

        // post notification after enabled services order changed
        if isEnabledServicesOrderChanged(source: oldEnabledServices, dest: newEnabledServices) {
            postUpdateServiceNotification()
        }
    }

    func isEnabledServicesOrderChanged(
        source: [QueryService],
        dest: [QueryService]
    ) -> Bool {
        !source.elementsEqual(dest) { sItem, dItem in
            sItem.serviceType() == dItem.serviceType() && sItem.name() == dItem.name()
        }
    }

    func postUpdateServiceNotification() {
        let userInfo: [String: Any] = [EZWindowTypeKey: windowTypeValue]
        let notification = Notification(name: .serviceHasUpdated, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(notification)
    }
}

@available(macOS 13, *)
#Preview {
    ServiceTab()
}
