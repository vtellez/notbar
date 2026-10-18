// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NotBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "NotBar",
            path: "Sources/NotBar"
        )
    ]
)
