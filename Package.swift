// swift-tools-version: 6.2

import PackageDescription

/// One library per wrapped command-line tool. Every wrapper depends only on SwiftyShell and the
/// internal `WrapperSupport` target, so a client imports exactly the tools it drives.
let wrappers: [(name: String, dependencies: [Target.Dependency])] = [
    // Apple
    ("XcodeBuildKit", []),
    ("XcrunKit", []),
    ("DeviceCtlKit", []),
    ("XcodeGenKit", []),
    ("TuistCLIKit", []),
    ("CocoaPodsKit", []),
    ("PlutilKit", []),
    ("SecurityKit", []),
    ("CodesignKit", []),
    ("IProxyKit", []),
    ("FrameitKit", []),
    // Android
    ("GradleKit", []),
    ("AdbKit", []),
    ("EmulatorKit", []),
    ("AVDManagerKit", []),
    ("SDKManagerKit", []),
    ("BundletoolKit", []),
    ("AndroidCLIKit", []),
    // Cross-platform
    ("FlutterKit", []),
    ("ReactNativeKit", []),
    ("SwiftPMKit", []),
    ("BazelKit", []),
]

let swiftyShell: Target.Dependency = .product(name: "SwiftyShell", package: "SwiftyShell")

let package = Package(
    name: "CLIWrappers",
    platforms: [.macOS(.v15)],
    products: wrappers.map { .library(name: $0.name, targets: [$0.name]) },
    dependencies: [
        // The `Swift` trait enables SwiftyShell's typed `swift` family, which SwiftPMKit extends.
        .package(url: "https://github.com/maniramezan/SwiftyShell.git", from: "0.7.0", traits: ["Swift"]),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.5.0"),
    ],
    targets: [
        .target(name: "WrapperSupport", dependencies: [swiftyShell]),
        .testTarget(name: "WrapperSupportTests", dependencies: ["WrapperSupport"]),
    ]
        + wrappers.map { .target(name: $0.name, dependencies: $0.dependencies + ["WrapperSupport", swiftyShell]) }
        + wrappers.map {
            .testTarget(name: "\($0.name)Tests", dependencies: [.target(name: $0.name), swiftyShell])
        },
    swiftLanguageModes: [.v6]
)
