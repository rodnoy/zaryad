// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ChargerMonitor",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ChargerMonitor", targets: ["App"]),
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Data", targets: ["Data"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: ["Presentation", "Domain", "Data"],
            path: "Sources/App"
        ),
        .target(
            name: "Domain",
            path: "Sources/Domain"
        ),
        .target(
            name: "Data",
            dependencies: ["Domain"],
            path: "Sources/Data",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        ),
        .target(
            name: "Presentation",
            dependencies: ["Domain", "Data"],
            path: "Sources/Presentation"
        ),
        .testTarget(
            name: "ChargerMonitorTests",
            dependencies: ["Domain", "Data", "Presentation"],
            path: "Tests/ChargerMonitorTests"
        )
    ]
)
