import Foundation
import SwiftyShell
import WrapperSupport

/// Typed `swift` package workflows: build, test with machine-readable output, coverage, format
/// lint, and manifest inspection.
///
/// A standalone family rather than an extension of SwiftyShell's `Swift` type: enabling that
/// trait adds a public type named `Swift` to every module that imports SwiftyShell, shadowing the
/// standard library's module name (`Swift.Duration` stops resolving).
///
/// ```swift
/// try await SwiftPM(context: shell).test(packagePath: ".", eventStream: "events.jsonl").run()
/// ```
public struct SwiftPM: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    public init(context: ShellContext = .init(), executablePath: String = "swift") {
        self.spec = CommandSpec(executable: executablePath, context: context)
    }

    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// **Mutating**: builds and runs package tests: `swift test --package-path <path> --parallel …`.
    ///
    /// `--parallel` is always passed: without it SwiftPM writes no XCTest results to `--xunit-output`.
    /// `workers` caps XCTest worker processes (`1` runs XCTest cases one at a time); Swift Testing
    /// schedules its own tests.
    ///
    /// - Parameters:
    ///   - eventStream: Path for the newline-delimited JSON event stream (`--event-stream-output-path`).
    ///   - xunit: Path for the XCTest JUnit report (`--xunit-output`).
    public func test(
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
    ) -> Self {
        var values = ["test", "--package-path", packagePath, "--parallel"]
        values += optionalOption("--num-workers", workers.map(String.init))
        values += ["--event-stream-output-path", eventStream]
        values += optionalOption("--xunit-output", xunit)
        values += optionalOption("--scratch-path", scratchPath)
        values += optionalOption("--attachments-path", attachments)
        values += flag("--enable-code-coverage", coverage)
        values += flag("--skip-build", skipBuild)
        values += optionalOption("--filter", filter)
        values += optionalOption("--skip", skip)
        return operation(values)
    }

    /// `swift test --show-codecov-path`: locates generated coverage without running tests.
    public func codeCoveragePath(packagePath: String, scratchPath: String? = nil) -> Self {
        operation(
            ["test", "--package-path", packagePath, "--show-codecov-path"] + optionalOption("--scratch-path", scratchPath)
        )
    }

    /// `swift build`, optionally of one product.
    public func build(
        packagePath: String,
        product: String? = nil,
        configuration: SwiftPMConfiguration = .debug,
        scratchPath: String? = nil,
        buildTests: Bool = false
    ) -> Self {
        operation(
            ["build", "--package-path", packagePath, "--configuration", configuration.rawValue]
                + optionalOption("--product", product) + optionalOption("--scratch-path", scratchPath)
                + flag("--build-tests", buildTests)
        )
    }

    /// `swift format lint --recursive --strict`: checks formatting without modifying sources.
    public func formatLint(paths: [String], configuration: String? = nil) -> Self {
        operation(["format", "lint", "--recursive", "--strict"] + optionalOption("--configuration", configuration) + paths)
    }

    /// `swift package describe --type json`. Evaluates `Package.swift`, which runs repository code.
    public func describePackage(packagePath: String) -> Self {
        operation(["package", "--package-path", packagePath, "describe", "--type", "json"])
    }

    /// `swift package dump-package`: the evaluated manifest as JSON. Runs `Package.swift`.
    public func dumpPackage(packagePath: String) -> Self {
        operation(["package", "--package-path", packagePath, "dump-package"])
    }

    /// `swift package show-dependencies --format json`.
    public func showDependencies(packagePath: String) -> Self {
        operation(["package", "--package-path", packagePath, "show-dependencies", "--format", "json"])
    }

    /// **Mutating**: `swift package resolve`.
    public func resolve(packagePath: String) -> Self {
        operation(["package", "--package-path", packagePath, "resolve"])
    }

    /// `swift --version`.
    public func version() -> Self {
        operation(["--version"])
    }

    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}

/// Build configurations accepted by `swift build --configuration`.
public enum SwiftPMConfiguration: String, Sendable, CaseIterable {
    case debug
    case release
}
