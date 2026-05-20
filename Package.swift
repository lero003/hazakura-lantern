// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "hazakura-lantern",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "HazakuraLLMManager",
            targets: ["HazakuraLLMManager"]
        )
    ],
    targets: [
        .target(
            name: "HazakuraLLMManagerCore"
        ),
        .executableTarget(
            name: "HazakuraLLMManager",
            dependencies: ["HazakuraLLMManagerCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "HazakuraLLMManagerCoreTests",
            dependencies: ["HazakuraLLMManagerCore"]
        )
    ]
)
