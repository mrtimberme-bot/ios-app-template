// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreKit",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "CoreKit", targets: ["CoreKit"])
    ],
    targets: [
        .target(
            name: "CoreKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
