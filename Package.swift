// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PromptDock",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PromptDock", targets: ["PromptDock"])
    ],
    targets: [
        .executableTarget(
            name: "PromptDock",
            path: "Sources/PromptDock"
        )
    ]
)
