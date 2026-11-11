// swift-tools-version: 6.0
// Local library-only manifest. Upstream source files are unmodified.
import PackageDescription
let package = Package(name: "Kadr", platforms: [.iOS(.v17)], products: [.library(name: "Kadr", targets: ["Kadr"])], targets: [.target(name: "Kadr", exclude: ["Kadr.docc"], swiftSettings: [.swiftLanguageMode(.v6)])])
