import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for `bazel` (or `bazelisk`): `bazel [startup options] <command> [options] [targets] [-- args]`.
///
/// ```swift
/// let output = try await Bazel(context: shell)
///     .test(["//app:unit_tests"])
///     .option(.config("ci"))
///     .option(.testOutput(.errors))
///     .option(.buildEventJSONFile("bep.json"))
///     .run()
/// ```
public struct Bazel: RunnableCommandFamily {
    private var spec: CommandSpec
    private var startup: [BazelStartupOption] = []
    private var subcommand: [String] = []
    private var options: [BazelOption] = []
    private var targets: [String] = []
    private var runArguments: [String] = []

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// - Parameter executablePath: `bazel`, `bazelisk`, or a workspace-local wrapper such as `./tools/bazel`.
    public init(context: ShellContext = .init(), executablePath: String = "bazel") {
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

    // MARK: - Options

    /// Adds a startup option, placed before the command.
    public func startupOption(_ value: BazelStartupOption) -> Self {
        modified(self) { $0.startup.append(value) }
    }

    /// Adds a command option, placed after the command and before targets.
    public func option(_ value: BazelOption) -> Self {
        modified(self) { $0.options.append(value) }
    }

    /// Adds several command options.
    public func options(_ values: [BazelOption]) -> Self {
        modified(self) { $0.options += values }
    }

    // MARK: - Commands

    /// `bazel build <targets>`.
    public func build(_ targets: [String]) -> Self {
        select(["build"], targets: targets)
    }

    /// `bazel test <targets>`.
    public func test(_ targets: [String]) -> Self {
        select(["test"], targets: targets)
    }

    /// `bazel run <target> -- <arguments>`. Named `runTarget` because `run()` executes the command.
    public func runTarget(_ target: String, arguments: [String] = []) -> Self {
        modified(select(["run"], targets: [target])) { $0.runArguments = arguments }
    }

    /// `bazel coverage <targets>`.
    public func coverage(_ targets: [String]) -> Self {
        select(["coverage"], targets: targets)
    }

    /// `bazel query <expression>`.
    public func query(_ expression: String, output: BazelQueryOutput? = nil) -> Self {
        modified(select(["query"], targets: [expression])) { family in
            output.map { family.options.append(.custom("--output=\($0.rawValue)")) }
        }
    }

    /// `bazel cquery <expression>`: query with build configuration applied.
    public func cquery(_ expression: String, output: BazelQueryOutput? = nil) -> Self {
        modified(select(["cquery"], targets: [expression])) { family in
            output.map { family.options.append(.custom("--output=\($0.rawValue)")) }
        }
    }

    /// `bazel aquery <expression>`: query the action graph.
    public func aquery(_ expression: String, output: BazelQueryOutput? = nil) -> Self {
        modified(select(["aquery"], targets: [expression])) { family in
            output.map { family.options.append(.custom("--output=\($0.rawValue)")) }
        }
    }

    /// `bazel info [key]`, e.g. `bazel-bin` or `output_base`.
    public func info(_ key: String? = nil) -> Self {
        select(["info"], targets: key.map { [$0] } ?? [])
    }

    /// `bazel clean`; `expunge` removes the whole output base.
    public func clean(expunge: Bool = false) -> Self {
        select(["clean"] + flag("--expunge", expunge), targets: [])
    }

    /// `bazel mod <subcommand>`, e.g. `graph` or `deps`.
    public func mod(_ subcommand: String, arguments: [String] = []) -> Self {
        select(["mod", subcommand], targets: arguments)
    }

    /// `bazel fetch <targets>`; every external repository when empty.
    public func fetch(_ targets: [String] = []) -> Self {
        select(["fetch"], targets: targets)
    }

    /// `bazel shutdown`.
    public func shutdown() -> Self {
        select(["shutdown"], targets: [])
    }

    /// `bazel version`.
    public func version() -> Self {
        select(["version"], targets: [])
    }

    /// Builds the raw `bazel` command.
    public func command() -> Command {
        modified(spec) {
            $0.globalArguments = startup.flatMap(\.arguments)
            $0.arguments = subcommand + options.flatMap(\.arguments) + targets
            $0.passthroughArguments = runArguments
        }
        .command()
    }

    private func select(_ command: [String], targets: [String]) -> Self {
        modified(self) {
            $0.subcommand = command
            $0.targets = targets
            $0.runArguments = []
        }
    }
}

/// A Bazel startup option (`bazel <startup> command`).
public enum BazelStartupOption: Sendable, Equatable {
    case outputBase(String)
    case outputUserRoot(String)
    case bazelrc(String)
    /// `--ignore_all_rc_files`.
    case ignoreAllRCFiles
    /// `--batch`: no server process.
    case batch
    case custom(String)

    public var arguments: [String] {
        switch self {
        case .outputBase(let path): ["--output_base=\(path)"]
        case .outputUserRoot(let path): ["--output_user_root=\(path)"]
        case .bazelrc(let path): ["--bazelrc=\(path)"]
        case .ignoreAllRCFiles: ["--ignore_all_rc_files"]
        case .batch: ["--batch"]
        case .custom(let value): [value]
        }
    }
}

/// A Bazel command option (`bazel command <option> targets`).
public enum BazelOption: Sendable, Equatable {
    /// `--config=<name>` from `.bazelrc`.
    case config(String)
    case compilationMode(BazelCompilationMode)
    /// `--platforms=<label>`.
    case platforms(String)
    /// `--ios_multi_cpus=<cpus>`, e.g. `sim_arm64`.
    case iosMultiCPUs([String])
    /// `--build_event_json_file=<path>`: newline-delimited Build Event Protocol JSON.
    case buildEventJSONFile(String)
    /// `--build_event_binary_file=<path>`.
    case buildEventBinaryFile(String)
    case testOutput(BazelTestOutput)
    /// `--test_filter=<filter>`, passed to the test runner (e.g. `MyTests/testFoo`).
    case testFilter(String)
    /// `--test_tag_filters=<tags>`; prefix a tag with `-` to exclude it.
    case testTagFilters([String])
    /// `--build_tag_filters=<tags>`.
    case buildTagFilters([String])
    /// `--runs_per_test=<n>`.
    case runsPerTest(Int)
    /// `--flaky_test_attempts=<n>`.
    case flakyTestAttempts(Int)
    /// `--test_env=<name>[=<value>]`.
    case testEnv(String, String?)
    /// `--action_env=<name>[=<value>]`.
    case actionEnv(String, String?)
    /// `--define=<name>=<value>`.
    case define(String, String)
    /// `--keep_going`.
    case keepGoing
    /// `--jobs=<n>`.
    case jobs(Int)
    /// `--color=no` and `--curses=no`, for logs.
    case plainOutput
    /// `--noshow_progress`.
    case noShowProgress
    /// `--verbose_failures`.
    case verboseFailures
    case custom(String)

    public var arguments: [String] {
        switch self {
        case .config(let name): ["--config=\(name)"]
        case .compilationMode(let mode): ["--compilation_mode=\(mode.rawValue)"]
        case .platforms(let label): ["--platforms=\(label)"]
        case .iosMultiCPUs(let cpus): ["--ios_multi_cpus=\(cpus.joined(separator: ","))"]
        case .buildEventJSONFile(let path): ["--build_event_json_file=\(path)"]
        case .buildEventBinaryFile(let path): ["--build_event_binary_file=\(path)"]
        case .testOutput(let mode): ["--test_output=\(mode.rawValue)"]
        case .testFilter(let filter): ["--test_filter=\(filter)"]
        case .testTagFilters(let tags): ["--test_tag_filters=\(tags.joined(separator: ","))"]
        case .buildTagFilters(let tags): ["--build_tag_filters=\(tags.joined(separator: ","))"]
        case .runsPerTest(let count): ["--runs_per_test=\(count)"]
        case .flakyTestAttempts(let count): ["--flaky_test_attempts=\(count)"]
        case .testEnv(let name, let value): ["--test_env=\(value.map { "\(name)=\($0)" } ?? name)"]
        case .actionEnv(let name, let value): ["--action_env=\(value.map { "\(name)=\($0)" } ?? name)"]
        case .define(let name, let value): ["--define=\(name)=\(value)"]
        case .keepGoing: ["--keep_going"]
        case .jobs(let count): ["--jobs=\(count)"]
        case .plainOutput: ["--color=no", "--curses=no"]
        case .noShowProgress: ["--noshow_progress"]
        case .verboseFailures: ["--verbose_failures"]
        case .custom(let value): [value]
        }
    }
}

public enum BazelCompilationMode: String, Sendable, CaseIterable {
    case fastbuild
    case dbg
    case opt
}

public enum BazelTestOutput: String, Sendable, CaseIterable {
    case summary
    case errors
    case all
    case streamed
}

public enum BazelQueryOutput: String, Sendable, CaseIterable {
    case label
    case labelKind = "label_kind"
    case build
    case xml
    case proto
    case jsonproto
    case graph
    case starlark
}
