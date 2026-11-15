import Foundation
import SwiftyShell
internal import WrapperSupport

/// A fluent wrapper for the `xcodegen` command.
///
/// XcodeGen generates Xcode project files from a YAML or JSON project spec.
/// This wrapper provides a typed, fluent API on top of the CLI.
///
/// ## Usage
/// ```swift
/// // Generate a project from the default project.yml
/// let output = try await XcodeGen(context: shell)
///     .generate()
///     .run()
///
/// // Generate from a custom spec with a specific project path
/// let output = try await XcodeGen(context: shell)
///     .generate()
///     .spec("custom-project.yml")
///     .projectDirectory("./MyApp")
///     .run()
///
/// // Dump the resolved spec (useful for debugging)
/// let output = try await XcodeGen(context: shell)
///     .dump()
///     .spec("project.yml")
///     .run()
/// ```
public struct XcodeGen: RunnableCommandFamily {
    private var commandSpec: CommandSpec
    private var subcommand: String?
    private var options: [XcodeGenOption] = []

    /// The shell context used when running this command family.
    public var context: ShellContext { commandSpec.config.context }

    // MARK: - Init

    /// Creates an `xcodegen` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcodegen") {
        self.commandSpec = CommandSpec(executable: executablePath, context: context)
    }

    // MARK: - RunnableCommandFamily

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.commandSpec.config = update($0.commandSpec.config) }
    }

    /// Redirects stdout for the built `xcodegen` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.commandSpec.stdout = destination }
    }

    /// Redirects stderr for the built `xcodegen` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.commandSpec.stderr = destination }
    }

    // MARK: - Subcommands

    /// `xcodegen generate` — Generate an Xcode project from a spec file.
    public func generate() -> Self {
        selecting("generate")
    }

    /// `xcodegen dump` — Dump the resolved project spec to stdout.
    public func dump() -> Self {
        selecting("dump")
    }

    /// `xcodegen cache` — Write or check the cache.
    public func cache() -> Self {
        selecting("cache")
    }

    // MARK: - Options

    /// Appends a typed `xcodegen` option.
    public func option(_ option: XcodeGenOption) -> Self {
        modified(self) { $0.options.append(option) }
    }

    /// Sets the project spec file path (`--spec <path>`).
    public func spec(_ path: String) -> Self {
        option(.spec(path))
    }

    /// Sets the project directory for the generated `.xcodeproj` (`--project <path>`).
    public func projectDirectory(_ path: String) -> Self {
        option(.project(path))
    }

    /// Disables the project generation cache (`--no-cache`).
    public func noCache() -> Self {
        option(.noCache)
    }

    /// Enables quiet mode — suppress non-error output (`--quiet`).
    public func quiet() -> Self {
        option(.quiet)
    }

    // MARK: - Command Builder

    /// Builds the raw `xcodegen` command.
    public func command() -> Command {
        modified(commandSpec) {
            $0.arguments = (subcommand.map { [$0] } ?? []) + options.flatMap(\.arguments)
        }.command()
    }

    private func selecting(_ name: String) -> Self {
        modified(self) { $0.subcommand = name }
    }
}
