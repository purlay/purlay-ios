// swift-tools-version: 6.2
import PackageDescription

// Swift 6 language mode, every warning an error; iOS 18 is the floor.
let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "PurlayModuleAPI",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "PurlayModuleAPI", targets: ["PurlayModuleAPI"])],
    targets: [
        .target(name: "PurlayModuleAPI", swiftSettings: strict),
        .testTarget(name: "PurlayModuleAPITests", dependencies: ["PurlayModuleAPI"], swiftSettings: strict),
    ],
    swiftLanguageModes: [.v6]
)
