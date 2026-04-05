// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ParticleFX",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ParticleFX", targets: ["ParticleFX"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ParticleFX",
            dependencies: [],
            path: "Sources/ParticleFX",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
