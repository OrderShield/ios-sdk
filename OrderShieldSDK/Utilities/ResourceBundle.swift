//
//  ResourceBundle.swift
//  OrderShieldSDK
//
//  Resolves the bundle that contains SDK assets (e.g. ordershield_icon).
//  Works when the SDK is used via Swift Package Manager (Bundle.module) or as a framework.
//

import UIKit

enum OrderShieldResourceBundle {
    /// Bundle that contains OrderShieldSDK assets (Assets.xcassets).
    /// Use this when loading images so they work both as SPM dependency and as framework.
    static var bundle: Bundle {
#if SWIFT_PACKAGE
        // When built as a Swift package (e.g. app adds SDK via SPM), this is the correct bundle.
        return Bundle.module
#else
        let classBundle = Bundle(for: OrderShieldHeaderView.self)
        // SPM-style consumption from Xcode: resources may be in OrderShieldSDK_OrderShieldSDK.bundle
        let resourceBundleNames = ["OrderShieldSDK_OrderShieldSDK", "OrderShieldSDKOrderShieldSDK"]
        for name in resourceBundleNames {
            if let url = classBundle.url(forResource: name, withExtension: "bundle"),
               let resourceBundle = Bundle(url: url) {
                return resourceBundle
            }
            if let url = Bundle.main.url(forResource: name, withExtension: "bundle"),
               let resourceBundle = Bundle(url: url) {
                return resourceBundle
            }
        }
        return classBundle
#endif
    }
}
