import Foundation
import SwiftyShell
import WrapperSupport

/// A typed wrapper for the `tuist` CLI, which generates Xcode projects from Swift manifests.
///
/// ```swift
/// try await Tuist(context: shell).install().path("App").run()
/// try await Tuist(context: shell).generate(open: false).path("App").run()
/// ```
public struct Tuist: RunnableCommandFamily {
    private var spec: CommandSpec
    private var options: [String] = []
    private var positionals: [String] = []

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    public init(context: ShellContext = .init(), executablePath: String = "tuist") {
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

    /// `--path <directory>`: the directory holding `Project.swift` or `Workspace.swift`.
    public func path(_ directory: String) -> Self {
        option(["--path", directory])
    }

    /// `--configuration <name>`.
    public func configuration(_ name: String) -> Self {
        option(["--configuration", name])
    }

    /// `--platform <platform>`, e.g. `ios`.
    public func platform(_ value: String) -> Self {
        option(["--platform", value])
    }

    /// `--device <name>` for `build`/`test`.
    public func device(_ name: String) -> Self {
        option(["--device", name])
    }

    /// `--os <version>` for `build`/`test`.
    public func os(_ version: String) -> Self {
        option(["--os", version])
    }

    /// `--verbose`.
    public func verbose() -> Self {
        option(["--verbose"])
    }

    /// Any other option for the selected subcommand.
    public func option(_ values: [String]) -> Self {
        modified(self) { $0.options += values }
    }

    // MARK: - Operations

    /// `tuist install`: resolves external dependencies declared in `Tuist/Package.swift`.
    public func install(update: Bool = false) -> Self {
        operation(["install"] + flag("--update", update))
    }

    /// `tuist generate`; `open: false` passes `--no-open`.
    ///
    /// - Parameter focusTargets: Targets to focus on; all targets when empty.
    public func generate(open: Bool = false, binaryCache: Bool? = nil, focusTargets: [String] = []) -> Self {
        var values = ["generate"] + flag("--no-open", !open)
        if let binaryCache {
            values.append(binaryCache ? "--binary-cache" : "--no-binary-cache")
        }
        return operation(values, positionals: focusTargets)
    }

    /// `tuist build [scheme]`.
    public func build(scheme: String? = nil, clean: Bool = false) -> Self {
        operation(["build"] + flag("--clean", clean), positionals: scheme.map { [$0] } ?? [])
    }

    /// `tuist test [scheme]`.
    public func test(scheme: String? = nil, testPlan: String? = nil) -> Self {
        operation(["test"] + optionalOption("--test-plan", testPlan), positionals: scheme.map { [$0] } ?? [])
    }

    /// `tuist clean [categories]`; everything when empty.
    public func clean(_ categories: [String] = []) -> Self {
        operation(["clean"], positionals: categories)
    }

    /// `tuist graph`, writing the dependency graph in `format`.
    public func graph(format: String = "json", outputPath: String? = nil) -> Self {
        operation(["graph", "--format", format, "--no-open"] + optionalOption("--output-path", outputPath))
    }

    /// `tuist version`.
    public func version() -> Self {
        operation(["version"])
    }

    public func command() -> Command {
        modified(spec) { $0.arguments += options + positionals }.command()
    }

    private func operation(_ values: [String], positionals: [String] = []) -> Self {
        modified(self) {
            $0.spec.arguments = values
            $0.positionals = positionals
        }
    }
}
