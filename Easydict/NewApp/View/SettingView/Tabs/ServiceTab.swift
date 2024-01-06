//
//  ServiceTab.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

enum ServiceWindowType: Int {
    case mini
    case fixed
    case main
}

struct ServiceTab: View {
    @State private var windowTypeValue = EZWindowType.mini.rawValue

    @State private var serviceTypes: [ServiceType] = []

    @State private var services: [QueryService] = []

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
            }
        }
        .listStyle(.inset)
        .clipShape(RoundedRectangle(cornerRadius: 10.0))
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
        serviceTypes = EZLocalStorage.shared().allServiceTypes(windowType)
        services = EZLocalStorage.shared().allServices(windowType)
    }

    func serviceToggled(index: Int, isEnable: Bool) {
        let service = services[index]
        service.enabled = isEnable
        if isEnable {
            service.enabledQuery = true
        }
        let windowType = EZWindowType(rawValue: windowTypeValue) ?? .none
        EZLocalStorage.shared().setService(services[index], windowType: windowType)
    }
}

#Preview {
    ServiceTab()
}
