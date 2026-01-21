//
//  DeviceInfo.swift
//  OrderShieldSDK
//
//  Created by rajkumar on 16/01/26.
//

import Foundation
import UIKit
import Darwin

class DeviceInfo {
    static func getDeviceId() -> String {
        if let deviceId = UserDefaults.standard.string(forKey: "OrderShieldSDK.deviceId") {
            return deviceId
        }
        
        let deviceId = "\(UIDevice.current.model)-\(UUID().uuidString.prefix(8))-\(UUID().uuidString.suffix(8))"
        UserDefaults.standard.set(deviceId, forKey: "OrderShieldSDK.deviceId")
        return deviceId
    }
    
    static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0)
            }
        }
        return modelCode ?? UIDevice.current.model
    }
    
    static func getOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    static func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static func getUserAgent() -> String {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "App"
        return "\(appName)/\(getAppVersion()) iOS/\(getOSVersion())"
    }
    
    static func getTimezone() -> String {
        return TimeZone.current.identifier
    }
    
    static func getIPAddress() -> String {
        // Note: This is a simplified version. In production, you might want to get the actual IP
        // For now, returning a placeholder that the server might handle
        return "0.0.0.0"
    }
}

