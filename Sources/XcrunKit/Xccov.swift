import Foundation
import SwiftyShell
internal import WrapperSupport

/// A typed wrapper for `xcrun xccov` commands.
public struct Xccov: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates a `xcrun xccov` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcrun") {
        self.spec = CommandSpec(executable: executablePath, prefix: ["xccov"], context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `xcrun xccov` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `xcrun xccov` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Uses `xccov view --report --json <xcresultPath>`.
    public func viewReportJSON(xcresultPath: String) -> Self {
        operation(["view", "--report", "--json", xcresultPath])
    }

    /// `xccov view --report [scope] [--json] <path>`: reads the coverage report in an `.xcresult`
    /// bundle.
    ///
    /// - Parameters:
    ///   - path: An `.xcresult` bundle.
    ///   - scope: Narrows the report to targets, one target's files, or one file's functions.
    ///   - json: Pass `--json` for machine-readable output.
    public func viewReport(path: String, scope: XccovScope? = nil, json: Bool = true) -> Self {
        operation(["view", "--report"] + (scope?.arguments ?? []) + flag("--json", json) + [path])
    }

    /// `xccov view --archive [--file-list | --file <path>] [--json] <xcresult>`: raw execution counts.
    ///
    /// - Parameters:
    ///   - xcresultPath: An `.xcresult` bundle.
    ///   - file: A source path to read counts for. `nil` lists the files instead when `fileList` is set.
    ///   - fileList: Pass `--file-list` to list files with coverage data.
    ///   - json: Pass `--json` for machine-readable output.
    public func viewArchive(xcresultPath: String, file: String? = nil, fileList: Bool = false, json: Bool = false) -> Self {
        operation(
            ["view", "--archive"] + flag("--file-list", fileList) + optionalOption("--file", file) + flag("--json", json)
                + [xcresultPath]
        )
    }

    /// `xccov diff --json [--path-equivalence <from,to>] <before> <after>`: compares two coverage
    /// reports (`.xccovreport`) or two `.xcresult` bundles.
    ///
    /// - Parameter pathEquivalence: Maps source paths in `before` onto `after`, as `from,to`.
    public func diff(before: String, after: String, pathEquivalence: String? = nil) -> Self {
        operation(["diff", "--json"] + optionalOption("--path-equivalence", pathEquivalence) + [before, after])
    }

    /// **Mutating**: `xccov merge [--outReport <path>] [--outArchive <path>] <inputs>...`.
    ///
    /// Writes `merged.xccovreport` and `merged.xccovarchive` into the working directory when the
    /// output paths are omitted.
    ///
    /// - Parameter inputs: Alternating reports and archives, in the order `xccov merge` expects.
    public func merge(inputs: [String], outReport: String? = nil, outArchive: String? = nil) -> Self {
        operation(["merge"] + optionalOption("--outReport", outReport) + optionalOption("--outArchive", outArchive) + inputs)
    }

    /// Builds the raw `xcrun xccov` command.
    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}

/// What `xccov view --report` narrows its output to.
public enum XccovScope: Sendable, Equatable, Hashable {
    /// `--only-targets`.
    case onlyTargets
    /// `--files-for-target <name>`.
    case filesForTarget(String)
    /// `--functions-for-file <name or path>`.
    case functionsForFile(String)

    var arguments: [String] {
        switch self {
        case .onlyTargets: ["--only-targets"]
        case .filesForTarget(let name): ["--files-for-target", name]
        case .functionsForFile(let file): ["--functions-for-file", file]
        }
    }
}
