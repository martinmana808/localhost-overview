// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalHostOverview",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LocalHostOverview", targets: ["LocalHostOverview"])
    ],
    targets: [
        .executableTarget(
            name: "LocalHostOverview",
            path: "LocalHostOverview"
        )
    ]
)
