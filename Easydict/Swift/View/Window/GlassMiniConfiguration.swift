//
//  GlassMiniConfiguration.swift
//  Easydict
//

import Defaults
import Foundation

extension Defaults.Keys {
    static let liquidGlassMini = Key<Bool>("EZConfiguration_LiquidGlassMini", default: false)
    static let liquidGlassMiniService = Key<String>(
        "EZConfiguration_LiquidGlassMiniService", default: ServiceType.google.rawValue
    )
}

/// Presentation preferences are independent of the classic mini window's service toggles.
@objcMembers
final class GlassMiniConfiguration: NSObject {
    static var enabled: Bool {
        if #available(macOS 26.0, *) {
            return Defaults[.liquidGlassMini]
        }
        return false
    }

    static func availableServices() -> [QueryService] {
        LocalStorage.shared().allServices(.mini).filter {
            $0.supportedQueryType().contains(.sentence)
        }
    }

    /// Never silently send the user's text to another provider if the selection was removed.
    static func selectedServices() -> [QueryService] {
        guard let service = availableServices().first(where: {
            $0.serviceTypeWithUniqueIdentifier() == Defaults[.liquidGlassMiniService]
        }) else { return [] }
        // This is a fresh instance. Do not persist the classic window's enabledQuery flags.
        service.enabled = true
        return [service]
    }
}
