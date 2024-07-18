//
//  BaiduService+ConfigurableService.swift
//  Easydict
//
//  Created by karl on 2024/7/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

extension EZBaiduTranslate {
    open override func configurationListItems() -> Any {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.baiduAppId, .baiduSecretKey]
        ) {
            BaiduServiceApiTypePicker()

            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.app_id.title",
                key: .baiduAppId
            )

            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.baidu.secret_key.title",
                key: .baiduSecretKey
            )
        }
    }
}

// MARK: - BaiduServiceApiTypePicker

struct BaiduServiceApiTypePicker: View {
    // MARK: Lifecycle

    init() {
        let selected = Defaults[.baiduServiceApiTypeKey]

        if selected == nil, !Self.appid.isEmpty, !Self.secretKey.isEmpty {
            self.selection = .secretKey
        } else {
            self.selection = selected ?? .web
        }
    }

    // MARK: Internal

    // MARK: - BaiduServiceConfigurationPickerSelection

    enum ApiType: String, CaseIterable, Identifiable, Defaults.Serializable {
        case web
        case secretKey

        // MARK: Internal

        var id: Self { self }

        var title: String {
            switch self {
            case .web:
                "Web API"
            case .secretKey:
                "Secret Key API"
            }
        }
    }

    static var appid: String {
        Defaults[.baiduAppId]
    }

    static var secretKey: String {
        Defaults[.baiduSecretKey]
    }

    var body: some View {
        Picker("service.configuration.baidu.api_picker.title", selection: $selection) {
            ForEach(ApiType.allCases, id: \.self) { selection in
                Text(selection.title).tag(selection)
            }
        }
        .padding(10)
        .onChange(of: selection) { newValue in
            validateSelection(newValue)
        }
        .alert(isPresented: $showAlert, error: PickerSelectionError(), actions: {
            Button("ok") {}
        })
    }

    // MARK: Private

    private struct PickerSelectionError: LocalizedError {
        var errorDescription: String? {
            NSLocalizedString("service.configuration.baidu.api_disable.title", comment: "")
        }
    }

    @State private var showAlert = false

    @State private var selection: ApiType {
        didSet {
            if oldValue == selection {
                return
            }
            Defaults[.baiduServiceApiTypeKey] = selection
        }
    }

    private func validateSelection(_ newValue: ApiType) {
        if newValue == .secretKey, Self.appid.isEmpty || Self.secretKey.isEmpty {
            selection = .web
            showAlert = true
        } else {
            selection = newValue
        }
    }
}
