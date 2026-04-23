// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TimesheetGenerator",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TimesheetGenerator",
            path: "Sources/TimesheetGenerator"
        ),
        .testTarget(
            name: "TimesheetGeneratorTests",
            dependencies: ["TimesheetGenerator"],
            path: "Tests/TimesheetGeneratorTests"
        )
    ]
)
