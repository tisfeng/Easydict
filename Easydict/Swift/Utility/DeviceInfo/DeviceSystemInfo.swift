//
//  DeviceSystemInfo.swift
//  Easydict
//
//  Created by tisfeng on 2025/12/22.
//  Copyright © 2025 izual. All rights reserved.
//

import Darwin
import Foundation
import IOKit

/// Provides device and system information for logging and diagnostics.
@objc(EZDeviceSystemInfo)
@objcMembers
final class DeviceSystemInfo: NSObject {
    // MARK: Internal

    /// Returns a dictionary containing app and device system information.
    static func getDeviceSystemInfo() -> [String: String] {
        let infoDictionary = Bundle.main.infoDictionary
        let appVersion = infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let buildVersion = infoDictionary?["CFBundleVersion"] as? String ?? ""

        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let machine = machineIdentifier()
        let deviceModel = deviceModel()
        let uuidString = deviceUUID()

        return [
            "Version": appVersion,
            "Build": buildVersion,
            "System": systemVersion,
            "Device": deviceModel,
            "Machine": machine,
            "UUID": uuidString,
        ]
    }

    /// Returns the system version as a semantic string, for example "14.0.0".
    static func getSystemVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    // MARK: Private

    /// Returns the device model identifier, for example "MacBookPro18,1".
    private static func deviceModel() -> String {
        var size: size_t = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else {
            return ""
        }

        var model = [CChar](repeating: 0, count: Int(size))
        let result = model.withUnsafeMutableBufferPointer { buffer -> Int32 in
            guard let baseAddress = buffer.baseAddress else {
                return -1
            }
            return sysctlbyname("hw.model", baseAddress, &size, nil, 0)
        }
        guard result == 0 else {
            return ""
        }

        return String(cString: model)
    }

    /// Returns the IOPlatform UUID for the current device.
    private static func deviceUUID() -> String {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )
        guard platformExpert != 0 else {
            return ""
        }
        defer {
            IOObjectRelease(platformExpert)
        }

        guard let uuid = IORegistryEntryCreateCFProperty(
            platformExpert,
            "IOPlatformUUID" as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            return ""
        }

        let uuidValue = uuid.takeRetainedValue()
        return uuidValue as? String ?? ""
    }

    /// Returns the machine identifier, for example "arm64".
    private static func machineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { pointer in
            pointer.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}
