// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "OrderShieldSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "OrderShieldSDK",
            targets: ["OrderShieldSDK"]
        ),
    ],
    targets: [
        .target(
            name: "OrderShieldSDK",
            path: "OrderShieldSDK",
            resources: [
                .process("Assets.xcassets")
            ]
        ),
    ]
)
