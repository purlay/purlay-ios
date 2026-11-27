// swift-tools-version: 6.2
import PackageDescription

let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "FeatureChat",
    platforms: [.iOS(.v18), .macOS(.v26)],
    products: [.library(name: "FeatureChat", targets: ["FeatureChat"])],
    dependencies: [.package(path: "../PurlayModuleAPI")],
    targets: [
        .target(name: "FeatureChat", dependencies: ["PurlayModuleAPI"], swiftSettings: strict),
        .testTarget(name: "FeatureChatTests", dependencies: ["FeatureChat", "PurlayModuleAPI"], swiftSettings: strict),
    ],
    swiftLanguageModes: [.v6]
)
