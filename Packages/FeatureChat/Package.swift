// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "FeatureChat",
    platforms: [.iOS(.v18), .macOS(.v26)],
    products: [.library(name: "FeatureChat", targets: ["FeatureChat"])],
    dependencies: [
        .package(path: "../PurlayModuleAPI"),
        .package(url: "https://github.com/purlay/purlay-swift", exact: "0.2.2"),
    ],
    targets: [
        .target(
            name: "FeatureChat",
            dependencies: [
                "PurlayModuleAPI", .product(name: "PurlayKit", package: "purlay-swift"),
                .product(name: "PurlayContract", package: "purlay-swift"),
            ],
            swiftSettings: strict),
        .testTarget(
            name: "FeatureChatTests",
            dependencies: ["FeatureChat", .product(name: "PurlayContract", package: "purlay-swift")],
            swiftSettings: strict),
    ],
    swiftLanguageModes: [.v6]
)
