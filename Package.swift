// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LilySwiftForPlayground",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "LilySwiftForPlayground",
            targets: [
                "LilySwiftForPlayground"
            ]
        )
    ],
    targets: [
        .target(
            name: "LilySwiftForPlayground",
            dependencies: [],
            path: "./Sources/",
            swiftSettings: [
                .define( "DEBUG", .when( platforms:[.iOS, .macOS, .macCatalyst, .visionOS], configuration:.debug ) )
            ]
        )
    ]
)
