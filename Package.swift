// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Maggy",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Maggy", targets: ["Maggy"])
    ],
    targets: [
        .executableTarget(
            name: "Maggy",
            dependencies: [],
            path: "Sources"
        )
    ]
)