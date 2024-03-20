// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LilySwiftForPlayground",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .macCatalyst(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "LilySwiftForPlayground",
            targets: [
                "LilySwiftForPlayground",
                "LilySwiftSupport"
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
        ),
        .target(
            name: "LilySwiftSupport",
            dependencies: [ "LilySwiftForPlayground" ],
            path: "./Supports/",
            swiftSettings: [
                .define( "DEBUG", .when( platforms:[.iOS, .macOS, .macCatalyst, .visionOS], configuration:.debug ) )
            ]
        )
    ]
)
