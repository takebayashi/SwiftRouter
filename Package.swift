// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SwiftRouter",
    dependencies: [
        .Package(url: "https://github.com/swift-server/http.git", majorVersion: 0, minor: 0),
    ]
)
