//
//  ServiceItemView.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/6.
//  Copyright © 2024 izual. All rights reserved.
//

import SwiftUI

struct ServiceItemView: View {
    @Binding var service: QueryService

    var toggleValueChanged: (Bool) -> Void

    var body: some View {
        HStack {
            Image(nsImage: NSImage(named: service.serviceType().rawValue) ?? NSImage())
                .resizable()
                .frame(maxWidth: 18.0, maxHeight: 18.0)

            Text(service.name())

            Toggle(isOn: $service.enabled.didSet(execute: { value in
                toggleValueChanged(value)
            })) {}
                .toggleStyle(.switch)
                .controlSize(.small)
        }

        .padding(4.0)
    }
}

#Preview {
    let service = EZLocalStorage.shared().allServices(.mini).first
    return ServiceItemView(service: .constant(service ?? QueryService())) { val in
        print("toggle value changed: \(val)")
    }
}
