// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "StudioCore", products: [.library(name: "StudioCore", targets: ["StudioCore"])], targets: [.target(name: "StudioCore"), .testTarget(name: "StudioCoreTests", dependencies: ["StudioCore"])])
