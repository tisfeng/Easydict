//
//  BaiduService+ConfigurableService.swift
//  Easydict
//
//  Created by karl on 2024/7/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Combine
import Defaults
import Foundation
import SwiftUI

// lazy init global var. , avoid duplicate creation
private let pickerObserver: BaiduServiceApiTypePickerObserver = {
    BaiduServiceApiTypePickerObserver()
}()

extension EZBaiduTranslate {
    open override func configurationListItems() -> Any {
        ServiceConfigurationSecretSectionView(
            service: self,
            observeKeys: [.baiduAppId, .baiduSecretKey]
        ) {
            BaiduServiceApiTypePicker(observer: pickerObserver)

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
    // MARK: Internal

    @ObservedObject var observer: BaiduServiceApiTypePickerObserver

    var body: some View {
        Picker("service.configuration.baidu.api_picker.title", selection: $observer.selectedApiType) {
            ForEach(BaiduServiceApiTypePickerObserver.ApiType.allCases, id: \.self) { selection in
                Text(selection.title).tag(selection)
            }
        }
        .padding(10)
        .onChange(of: observer.selectedApiType) { newValue in
            observer.validateSelection(newValue)
        }
        .alert(isPresented: $observer.showAlert, error: PickerSelectionError(), actions: {
            Button("ok") {}
        })
    }

    // MARK: Private

    private struct PickerSelectionError: LocalizedError {
        var errorDescription: String? {
            NSLocalizedString("service.configuration.baidu.api_disable.title", comment: "")
        }
    }
}

// MARK: - BaiduServiceApiTypePickerObserver

final class BaiduServiceApiTypePickerObserver: ObservableObject {
    // MARK: Lifecycle

    init() {
        let selectedApiType = Defaults[.baiduServiceApiTypeKey]

        if selectedApiType == nil, !Self.appid.isEmpty, !Self.secretKey.isEmpty {
            self.selectedApiType = .secretKey
        } else {
            self.selectedApiType = selectedApiType ?? .web
        }

        appIdAndSecretKeyListener()
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }

    // MARK: Internal

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

    // MARK: Fileprivate

    @Published fileprivate var showAlert = false

    @Published fileprivate var selectedApiType: ApiType {
        didSet {
            Defaults[.baiduServiceApiTypeKey] = selectedApiType
        }
    }

    fileprivate func validateSelection(_ newValue: ApiType) {
        if newValue == .secretKey, Self.appid.isEmpty || Self.secretKey.isEmpty {
            selectedApiType = .web
            showAlert = true
        } else {
            selectedApiType = newValue
        }
    }

    // MARK: Private

    private var cancellables: Set<AnyCancellable> = []

    private func appIdAndSecretKeyListener() {
        let keys: [Defaults.Key<String>] = [.baiduAppId, .baiduSecretKey]
        Defaults.publisher(keys: keys)
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                let hasEmptyInput = keys.contains(where: { Defaults[$0].isEmpty })
                if hasEmptyInput, selectedApiType == .secretKey {
                    selectedApiType = .web
                }
            }.store(in: &cancellables)
    }
}
