// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SwiftRouter",
    dependencies: [
        .package(url: "https://github.com/swift-server/http.git", .branch("develop")),
    ],
    targets: [
        .target(name: "SwiftRouter", dependencies: ["SwiftServerHTTP"]),
        .testTarget(name: "SwiftRouterTests", dependencies: ["SwiftRouter"]),
    ]
)
