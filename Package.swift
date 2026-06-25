// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Rescale",
    platforms: [
        // Menu bar agent built on AppKit; macOS 13 is a safe modern floor.
        .macOS(.v13)
    ],
    targets: [
        // An *executable* target: produces a runnable binary, not a library.
        // Swift treats Sources/Rescale/main.swift as the program entry point.
        .executableTarget(
            name: "Rescale",
            path: "Sources/Rescale",
            resources: [.copy("Resources")]
        )
    ]
)
