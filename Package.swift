// swift-tools-version: 6.2

import PackageDescription

let swiftyShell: Target.Dependency = .product(name: "SwiftyShell", package: "SwiftyShell")
let logging: Target.Dependency = .product(name: "Logging", package: "swift-log")

/// One library per wrapped command-line tool. Every wrapper depends only on SwiftyShell and the
/// internal `WrapperSupport` target, so a client imports exactly the tools it drives.
let wrappers: [(name: String, dependencies: [Target.Dependency])] = [
    // Apple
    ("XcodeBuildKit", [logging]),
    ("XcrunKit", []),
    ("LLVMCovKit", []),
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

/// `swift-docc-plugin` (and its SymbolKit dependency) is only needed to build the documentation
/// site, so it is declared only when `docs.yml` or a local docs build sets `CLI_WRAPPERS_DOCS`.
/// Consumers resolve and clone neither.
var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/maniramezan/SwiftyShell.git", from: "0.7.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.16.1"),
]
if Context.environment["CLI_WRAPPERS_DOCS"] != nil {
    dependencies.append(.package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.5.0"))
}

let package = Package(
    name: "CLIWrappers",
    platforms: [.macOS(.v15)],
    products: wrappers.map { .library(name: $0.name, targets: [$0.name]) },
    dependencies: dependencies,
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
