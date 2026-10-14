import Foundation
import SwiftyShell

/// Package-workflow operations on SwiftyShell's typed `swift` command family.
///
/// SwiftyShell models the `swift` toolchain itself; these add the package test, coverage,
/// formatting, and manifest-inspection invocations that automation needs, with their output flags.
///
/// ```swift
/// try await Swift(context: shell).packageTests(packagePath: ".", eventStream: "events.jsonl").run()
/// ```
extension Swift {
    /// `swift test --parallel … --event-stream-output-path <path>` for a package.
    ///
    /// `--parallel` is always passed: without it SwiftPM writes no XCTest results to `--xunit-output`.
    /// `workers` caps XCTest worker processes (`1` runs XCTest cases one at a time); Swift Testing
    /// schedules its own tests.
    public func packageTests(
        packagePath: String,
        scratchPath: String? = nil,
        eventStream: String,
        attachments: String? = nil,
        coverage: Bool = false,
        skipBuild: Bool = false,
        filter: String? = nil,
        skip: String? = nil,
        xunit: String? = nil,
        workers: Int? = nil
    ) -> Swift {
        var test = self.test().packagePath(packagePath).codeCoverage(coverage).skipBuild(skipBuild)
        if let scratchPath { test = test.scratchPath(scratchPath) }
        if let filter { test = test.filter(filter) }
        if let skip { test = test.skip(skip) }
        var extra = ["--parallel"]
        if let workers { extra += ["--num-workers", String(workers)] }
        extra += ["--event-stream-output-path", eventStream]
        if let xunit { extra += ["--xunit-output", xunit] }
        if let attachments { extra += ["--attachments-path", attachments] }
        return test.arguments(extra)
    }

    /// `swift test --show-codecov-path`: locates generated coverage without running tests.
    public func codeCoveragePath(packagePath: String, scratchPath: String? = nil) -> Swift {
        var test = self.test().packagePath(packagePath)
        if let scratchPath { test = test.scratchPath(scratchPath) }
        return test.argument("--show-codecov-path")
    }

    /// `swift build` of one product in a package.
    public func buildProduct(
        _ product: String? = nil,
        packagePath: String,
        configuration: SwiftBuildConfiguration = .debug,
        scratchPath: String? = nil
    ) -> Swift {
        var build = self.build().packagePath(packagePath).configuration(configuration)
        if let product { build = build.product(product) }
        if let scratchPath { build = build.scratchPath(scratchPath) }
        return build
    }

    /// `swift format lint --recursive --strict`: checks formatting without modifying sources.
    public func formatLint(paths: [String], configuration: String? = nil) -> Swift {
        subcommand("format").arguments(
            ["lint", "--recursive", "--strict"] + (configuration.map { ["--configuration", $0] } ?? [])
        )
        .positionalArguments(paths)
    }

    /// `swift package describe --type json`: targets, products, and platforms. Evaluates the
    /// manifest, which runs the package's `Package.swift`.
    public func describePackage(packagePath: String) -> Swift {
        package("describe").packagePath(packagePath).arguments(["--type", "json"])
    }

    /// `swift package dump-package`: the evaluated manifest as JSON. Runs `Package.swift`.
    public func dumpPackage(packagePath: String) -> Swift {
        package("dump-package").packagePath(packagePath)
    }

    /// `swift package show-dependencies --format json`.
    public func showDependencies(packagePath: String) -> Swift {
        package("show-dependencies").packagePath(packagePath).arguments(["--format", "json"])
    }

    /// `swift package resolve`.
    public func resolvePackages(packagePath: String) -> Swift {
        package("resolve").packagePath(packagePath)
    }
}
