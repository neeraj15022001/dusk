// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dusk",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Dusk", targets: ["Dusk"])],
    targets: [
        .target(name: "DuskCore"),
        .executableTarget(name: "Dusk", dependencies: ["DuskCore"]),
        // Command Line Tools do not ship XCTest. This runner needs only Swift.
        .executableTarget(name: "DuskChecks", dependencies: ["DuskCore"], path: "Tests/DuskCoreTests")
    ]
)
