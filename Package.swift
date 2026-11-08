// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ADBStudio",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ADBStudio",
            targets: ["ADBStudio"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ADBStudio",
            path: "Sources"
        ),
        .testTarget(
            name: "ADBStudioTests",
            dependencies: ["ADBStudio"],
            path: "Tests/ADBStudioTests"
        )
    ]
)
