//
//  Bundle+OrderShield.swift
//  OrderShieldSDK
//
//  Single place for the SDK resource bundle: SPM uses Bundle.module,
//  framework build uses the class bundle. Use Bundle.orderShield when loading assets.
//

import Foundation

extension Bundle {
    /// Bundle that contains OrderShieldSDK assets (e.g. ordershield_icon).
    /// Use when loading images so they work when the SDK is added via SPM or as a framework.
    static var orderShield: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: OrderShieldFooterView.self)
        #endif
    }
}
