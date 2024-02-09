//
//  TTSServiceType.swift
//  Easydict
//
//  Created by 戴藏龙 on 2024/1/13.
//  Copyright © 2024 izual. All rights reserved.
//

import Defaults
import Foundation

enum TTSServiceType: String, CaseIterable {
    case youdao = "Youdao"
    case bing = "Bing"
    case google = "Google"
    case baidu = "Baidu"
    case apple = "Apple"
}

@available(macOS 13, *)
extension TTSServiceType: CustomLocalizedStringResourceConvertible {
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .youdao:
            "setting.tts_service.options.youdao"
        case .bing:
            "setting.tts_service.options.bing"
        case .google:
            "setting.tts_service.options.google"
        case .baidu:
            "setting.tts_service.options.baidu"
        case .apple:
            "setting.tts_service.options.apple"
        }
    }
}

extension TTSServiceType: Defaults.Serializable {
    // while in the future, ServiceType was deleted, then you can safely delete this struct and `bridge`
    struct TTSServiceTypeBridge: Defaults.Bridge {
        func serialize(_ value: TTSServiceType?) -> String? {
            guard let value else { return nil }
            switch value {
            case .youdao:
                return ServiceType.youdao.rawValue
            case .bing:
                return ServiceType.bing.rawValue
            case .google:
                return ServiceType.google.rawValue
            case .baidu:
                return ServiceType.baidu.rawValue
            case .apple:
                return ServiceType.apple.rawValue
            }
        }

        func deserialize(_ object: String?) -> TTSServiceType? {
            guard let object else { return nil }
            switch object {
            case "Youdao":
                return .youdao
            case "Bing":
                return .bing
            case "Google":
                return .google
            case "Baidu":
                return .baidu
            case "Apple":
                return .apple
            default:
                return nil
            }
        }

        typealias Value = TTSServiceType

        typealias Serializable = String
    }

    static let bridge = TTSServiceTypeBridge()
}
