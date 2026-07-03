// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AbletonBridgeOSC",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.60.0"),
        .package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.20.0"),
        .package(url: "https://github.com/1024jp/GCDWebServer.git", branch: "master"),
        .package(url: "https://github.com/Dschee/SwiftOSC.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "AbletonBridge",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOExtras", package: "swift-nio-extras"),
                "SwiftOSC",
                "SharedModels"
            ],
            path: "Sources/AbletonBridge"
        ),
        .target(
            name: "LogicBridge",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                "GCDWebServer",
                "SharedModels"
            ],
            path: "Sources/LogicBridge"
        ),
        .target(
            name: "SharedModels",
            path: "Sources/Shared"
        ),
        .testTarget(
            name: "AbletonBridgeTests",
            dependencies: ["AbletonBridge", "SharedModels"],
            path: "Tests/AbletonBridge"
        ),
        .testTarget(
            name: "LogicBridgeTests",
            dependencies: ["LogicBridge", "SharedModels"],
            path: "Tests/LogicBridge"
        )
    ]
)
