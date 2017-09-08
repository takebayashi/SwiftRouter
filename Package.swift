// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SwiftRouter",
    dependencies: [
        .package(url: "https://github.com/swift-server/http.git", .exact("0.0.1")),
    ],
    targets: [
        .target(name: "SwiftRouter", dependencies: ["SwiftServerHttp"]),
        .testTarget(name: "SwiftRouterTests", dependencies: ["SwiftRouter"]),
    ]
)
