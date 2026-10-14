import Foundation
import SwiftyShell

/// A typed wrapper for `xcrun xcresulttool`, which reads and exports `.xcresult` bundles.
///
/// Uses the Xcode 16+ `get test-results` / `get build-results` grammar. `legacyObject` covers the
/// older object graph, which recent Xcode versions only expose behind `--legacy`.
///
/// ```swift
/// let summary = try await XCResultTool(context: shell).testResultsSummary(path: "build/tests.xcresult").run()
/// ```
public struct XCResultTool: RunnableCommandFamily {
    private var xcrun: Xcrun
    private var arguments: [String] = []

    /// The shell context used when running this command family.
    public var context: ShellContext { xcrun.context }

    public init(context: ShellContext = .init()) {
        self.xcrun = Xcrun(context: context)
    }

    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        copy { $0.xcrun = $0.xcrun.updatingConfiguration(update) }
    }

    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        copy { $0.xcrun = $0.xcrun.settingStdoutDestination(destination) }
    }

    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        copy { $0.xcrun = $0.xcrun.settingStderrDestination(destination) }
    }

    // MARK: - Test results

    /// `get test-results summary`.
    public func testResultsSummary(path: String, compact: Bool = true) -> Self {
        operation(["get", "test-results", "summary", "--path", path] + (compact ? ["--compact"] : []))
    }

    /// `get test-results tests`: the test tree with per-test outcomes.
    public func testResultsTests(path: String, compact: Bool = true) -> Self {
        operation(["get", "test-results", "tests", "--path", path] + (compact ? ["--compact"] : []))
    }

    /// `get test-results test-details` for one test identifier.
    public func testDetails(testID: String, path: String, compact: Bool = true) -> Self {
        operation(
            ["get", "test-results", "test-details", "--test-id", testID, "--path", path] + (compact ? ["--compact"] : [])
        )
    }

    /// `get test-results activities` for one test identifier.
    public func testActivities(testID: String, path: String, compact: Bool = true) -> Self {
        operation(
            ["get", "test-results", "activities", "--test-id", testID, "--path", path] + (compact ? ["--compact"] : [])
        )
    }

    /// `get test-results metrics`.
    public func testMetrics(path: String, compact: Bool = true) -> Self {
        operation(["get", "test-results", "metrics", "--path", path] + (compact ? ["--compact"] : []))
    }

    // MARK: - Build results and logs

    /// `get build-results`: warnings, errors, and analyzer issues.
    public func buildResults(path: String, compact: Bool = true) -> Self {
        operation(["get", "build-results", "--path", path] + (compact ? ["--compact"] : []))
    }

    /// `get log --type <kind>`.
    public func log(path: String, type: XCResultLogType, compact: Bool = true) -> Self {
        operation(["get", "log", "--path", path, "--type", type.rawValue] + (compact ? ["--compact"] : []))
    }

    /// `get content-availability`: which kinds of data the bundle contains.
    public func contentAvailability(path: String, compact: Bool = true) -> Self {
        operation(["get", "content-availability", "--path", path] + (compact ? ["--compact"] : []))
    }

    /// `get object --legacy --format json`, optionally for one object `id`.
    public func legacyObject(path: String, id: String? = nil) -> Self {
        operation(["get", "object", "--legacy", "--path", path, "--format", "json"] + (id.map { ["--id", $0] } ?? []))
    }

    // MARK: - Export and merge

    /// `export <kind> --path --output-path`.
    public func export(_ kind: XCResultExportKind, path: String, outputPath: String, testID: String? = nil) -> Self {
        operation(
            ["export", kind.rawValue, "--path", path, "--output-path", outputPath] + (testID.map { ["--test-id", $0] } ?? [])
        )
    }

    /// `merge --output-path <output> <bundles>`.
    public func merge(_ bundles: [String], outputPath: String) -> Self {
        operation(["merge", "--output-path", outputPath] + bundles)
    }

    /// `version`.
    public func version() -> Self {
        operation(["version"])
    }

    /// Builds the raw `xcrun xcresulttool` command.
    public func command() -> Command {
        xcrun.tool("xcresulttool").trailingArguments(arguments).command()
    }

    private func operation(_ values: [String]) -> Self {
        copy { $0.arguments = values }
    }

    private func copy(_ update: (inout Self) -> Void) -> Self {
        var value = self
        update(&value)
        return value
    }
}

/// Log kinds accepted by `xcresulttool get log --type`.
public enum XCResultLogType: String, Sendable, CaseIterable {
    case build
    case action
    case console
}

/// Exportable content kinds accepted by `xcresulttool export`.
public enum XCResultExportKind: String, Sendable, CaseIterable {
    case attachments
    case diagnostics
    case metrics
}
