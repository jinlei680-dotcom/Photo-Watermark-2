// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhotoWatermark",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PhotoWatermark", targets: ["PhotoWatermark"])
    ],
    targets: [
        .executableTarget(
            name: "PhotoWatermark",
            path: "PhotoWatermark"
        )
    ]
)