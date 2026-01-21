//
//  AppDelegate.swift
//  TestAppExample
//
//  Example AppDelegate for testing OrderShieldSDK
//

import UIKit
import OrderShieldSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Optional: Configure SDK early in app lifecycle
        // You can also configure it in ViewController
        // OrderShield.shared.configure(apiKey: "your-api-key-here")
        
        return true
    }
}

