import Foundation
import SwiftyShell
internal import WrapperSupport

/// A typed wrapper for the `xcode-select` command.
public struct XcodeSelect: RunnableCommandFamily {
    private var spec: CommandSpec

    /// The shell context used when running this command family.
    public var context: ShellContext { spec.config.context }

    /// Creates a `xcode-select` command family bound to a shell context.
    ///
    /// - Parameter executablePath: The executable to run, resolved through `PATH` when it has no slash.
    public init(context: ShellContext = .init(), executablePath: String = "xcode-select") {
        self.spec = CommandSpec(executable: executablePath, context: context)
    }

    /// Returns a new value with updated shared tool configuration.
    public func updatingConfiguration(_ update: (ToolConfiguration) -> ToolConfiguration) -> Self {
        modified(self) { $0.spec.config = update($0.spec.config) }
    }

    /// Redirects stdout for the built `xcode-select` command.
    public func settingStdoutDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stdout = destination }
    }

    /// Redirects stderr for the built `xcode-select` command.
    public func settingStderrDestination(_ destination: OutputDestination) -> Self {
        modified(self) { $0.spec.stderr = destination }
    }

    /// Uses `xcode-select -p` to print the selected developer directory.
    public func printPath() -> Self {
        operation(["-p"])
    }

    /// Builds the raw `xcode-select` command.
    public func command() -> Command {
        spec.command()
    }

    private func operation(_ values: [String]) -> Self {
        modified(self) { $0.spec.arguments = values }
    }
}
