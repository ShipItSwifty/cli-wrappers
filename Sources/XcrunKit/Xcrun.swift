import Foundation
import SwiftyShell
internal import WrapperSupport

/// A fluent wrapper for the `xcrun` command.
public struct Xcrun: RunnableCommandFamily {
    private var spec: CommandSpec
    private var options: [XcrunOption] = []
    private var trailing: [String] = []

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates an `xcrun` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcrun") {
        self.spec = CommandSpec(executable: executablePath, context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `xcrun` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `xcrun` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Appends a typed `xcrun` option.
    public func option(_ option: XcrunOption) -> Self {
        modified(self) { $0.options.append(option) }
    }

    /// Appends multiple typed `xcrun` options.
    public func options(_ values: [XcrunOption]) -> Self {
        modified(self) { $0.options += values }
    }

    /// Appends a tool name such as `simctl`.
    public func tool(_ value: String) -> Self {
        trailingArgument(value)
    }

    /// Appends a trailing argument.
    public func trailingArgument(_ value: String) -> Self {
        modified(self) { $0.trailing.append(value) }
    }

    /// Appends multiple trailing arguments.
    public func trailingArguments(_ values: [String]) -> Self {
        modified(self) { $0.trailing += values }
    }

    /// Enters the typed `simctl` command family.
    public func simctl() -> Simctl {
        Simctl(xcrun: self)
    }

    /// Builds the raw `xcrun` command.
    public func command() -> Command {
        modified(spec) { $0.arguments = options.flatMap(\.arguments) + trailing }.command()
    }
}
