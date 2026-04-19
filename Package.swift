// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Slumber",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Slumber", targets: ["Slumber"])
    ],
    targets: [
        .target(
            name: "Slumber",
            path: "SleepApp"
        )
    ]
)
