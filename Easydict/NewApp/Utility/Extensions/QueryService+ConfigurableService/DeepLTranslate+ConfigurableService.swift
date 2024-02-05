//
//  DeepLTranslate+ConfigurableService.swift
//  Easydict
//
//  Created by phlpsong on 2024/1/30.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation
import SwiftUI

enum DeepLAPIUsagePriority: String, CaseIterable, Hashable {
    case webFirst = "0"
    case authKeyFirst = "1"
    case authKeyOnly = "2"
}

extension DeepLAPIUsagePriority: Defaults.Serializable {
    public static var bridge: Bridge = .init()

    public struct Bridge: Defaults.Bridge {
        public func serialize(_ value: DeepLAPIUsagePriority?) -> String? {
            guard let value else { return DeepLAPIUsagePriority.webFirst.rawValue }
            return "\(value.rawValue)"
        }

        public func deserialize(_ object: String?) -> DeepLAPIUsagePriority? {
            guard let object else { return DeepLAPIUsagePriority.webFirst }
            return DeepLAPIUsagePriority(rawValue: object) ?? DeepLAPIUsagePriority.webFirst
        }

        public typealias Value = DeepLAPIUsagePriority

        public typealias Serializable = String
    }
}

extension DeepLAPIUsagePriority: EnumLocalizedStringConvertible {
    var title: String {
        switch self {
        case .webFirst:
            return NSLocalizedString("service.configuration.deepl.web_first.title", bundle: .main, comment: "")
        case .authKeyFirst:
            return NSLocalizedString("service.configuration.deepl.authkey_first.title", bundle: .main, comment: "")
        case .authKeyOnly:
            return NSLocalizedString("service.configuration.deepl.authkey_only.title", bundle: .main, comment: "")
        }
    }
}

@available(macOS 13.0, *)
extension EZDeepLTranslate: ConfigurableService {
    func configurationListItems() -> some View {
        EZDeepLTranslateConfigurationView(service: self)
    }
}

@available(macOS 13.0, *)
private struct EZDeepLTranslateConfigurationView: View {
    let service: EZDeepLTranslate

    @Default(.deepLTranslation) var apiUsagePriority

    var body: some View {
        ServiceConfigurationSecretSectionView(service: service, observeKeys: [.deepLAuth]) {
            ServiceConfigurationSecureInputCell(
                textFieldTitleKey: "service.configuration.deepl.auth_key.title",
                key: .deepLAuth
            )

            ServiceConfigurationInputCell(
                textFieldTitleKey: "service.configuration.deepl.endpoint.title",
                key: .deepLTranslateEndPointKey,
                placeholder: "service.configuration.deepl.endpoint.placeholder"
            )

            Picker("service.configuration.deepl.translation.title", selection: $apiUsagePriority) {
                ForEach(DeepLAPIUsagePriority.allCases, id: \.rawValue) { value in
                    Text(value.title)
                        .tag(value)
                }
            }
            .padding(10)
        }
    }
}
