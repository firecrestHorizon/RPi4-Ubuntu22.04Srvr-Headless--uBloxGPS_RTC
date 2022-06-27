// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "helloGPS",
    dependencies: [
      .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.1")
    ],
    targets: [
        .executableTarget(
            name: "helloGPS",
            dependencies: ["SwiftyGPIO"])
    ]
)
