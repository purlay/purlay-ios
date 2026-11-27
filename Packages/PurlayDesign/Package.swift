// swift-tools-version: 6.2
import PackageDescription

// Swift 6 language mode, every warning an error; iOS 18 is the floor.
let strict: [SwiftSetting] = [.treatAllWarnings(as: .error)]

let package = Package(
    name: "PurlayDesign",
    platforms: [.iOS(.v18), .macOS(.v26)],
    products: [.library(name: "PurlayDesign", targets: ["PurlayDesign"])],
    dependencies: [.package(url: "https://github.com/purlay/purlay-swift", exact: "0.3.1")],
    targets: [
        .target(
            name: "PurlayDesign", dependencies: [.product(name: "PurlayTokens", package: "purlay-swift")],
            swiftSettings: strict),
        .testTarget(name: "PurlayDesignTests", dependencies: ["PurlayDesign"], swiftSettings: strict),
    ],
    swiftLanguageModes: [.v6]
)
